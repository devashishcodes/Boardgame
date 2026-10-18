#!/usr/bin/env python3
"""CI report: detailed multi-line Slack message + GitHub Actions summary.

Reads results from the files other CI steps left behind:
  target/surefire-reports/TEST-*.xml   (unit tests)
  target/sonar/report-task.txt         (SonarCloud task info -> quality gate + metrics)
  trivy-report/trivy.json              (Trivy vulnerabilities)
Step outcomes come in as env vars (OUT_*), values: success/failure/skipped/cancelled.
Output: $GITHUB_STEP_SUMMARY (markdown) and $GITHUB_OUTPUT `text` (Slack mrkdwn).
This script never fails the pipeline: every section is wrapped in try/except.
"""
import base64
import glob
import json
import os
import subprocess
import time
import urllib.request
import uuid
import xml.etree.ElementTree as ET
from collections import Counter

E = os.environ.get

ICON = {
    "success": ":white_check_mark:",
    "failure": ":x:",
    "skipped": ":fast_forward:",
    "cancelled": ":no_entry_sign:",
}
WORD = {"success": "passed", "failure": "FAILED", "skipped": "skipped", "cancelled": "cancelled"}
SEV_ORDER = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]


def outcome(name):
    return E(name, "skipped") or "skipped"


def slack_escape(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def http_json(url, token=None, timeout=20):
    req = urllib.request.Request(url)
    if token:
        auth = base64.b64encode(f"{token}:".encode()).decode()
        req.add_header("Authorization", f"Basic {auth}")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.load(resp)


# ---------------------------------------------------------------- unit tests
def read_tests():
    total = failures = errors = skipped = 0
    seconds = 0.0
    rows = []
    for path in sorted(glob.glob("target/surefire-reports/TEST-*.xml")):
        try:
            root = ET.parse(path).getroot()
            n = int(root.get("tests", 0))
            f = int(root.get("failures", 0))
            e = int(root.get("errors", 0))
            s = int(root.get("skipped", 0))
            t = float(str(root.get("time", 0)).replace(",", ""))
        except (ET.ParseError, ValueError):
            continue
        total, failures, errors, skipped, seconds = total + n, failures + f, errors + e, skipped + s, seconds + t
        rows.append((root.get("name", os.path.basename(path)), n, f, e, s, t))
    if not rows:
        return None
    return {"total": total, "failures": failures, "errors": errors, "skipped": skipped, "seconds": seconds, "rows": rows}


# ------------------------------------------------------------------- sonar
def read_sonar():
    path = "target/sonar/report-task.txt"
    if not os.path.exists(path):
        return None
    kv = {}
    with open(path) as fh:
        for line in fh:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                kv[k] = v
    token = E("SONAR_TOKEN")
    info = {"dashboard": kv.get("dashboardUrl", ""), "gate": None, "conditions": [], "measures": {}, "error": None}
    try:
        analysis_id = None
        for _ in range(30):  # max ~90s: Sonar background task ka wait
            task = http_json(kv["ceTaskUrl"], token)["task"]
            if task["status"] == "SUCCESS":
                analysis_id = task.get("analysisId")
                break
            if task["status"] in ("FAILED", "CANCELED"):
                info["error"] = f"Sonar task {task['status']}"
                return info
            time.sleep(3)
        if not analysis_id:
            info["error"] = "Sonar analysis abhi process ho raha hai"
            return info
        server, key = kv["serverUrl"], kv["projectKey"]
        gate = http_json(f"{server}/api/qualitygates/project_status?analysisId={analysis_id}", token)["projectStatus"]
        info["gate"] = gate.get("status")
        info["conditions"] = [c for c in gate.get("conditions", []) if c.get("status") != "OK"]
        metrics = "bugs,vulnerabilities,code_smells,security_hotspots,coverage,duplicated_lines_density,ncloc"
        data = http_json(f"{server}/api/measures/component?component={key}&metricKeys={metrics}", token)
        for m in data["component"]["measures"]:
            info["measures"][m["metric"]] = m.get("value", "?")
        info["issues"] = read_sonar_issues(server, key, token)
    except Exception as exc:  # noqa: BLE001 - report kabhi pipeline fail na kare
        info["error"] = f"{type(exc).__name__}: {exc}"
    return info


def read_sonar_issues(server, key, token):
    """Open vulnerabilities/bugs ki chhoti list (file:line + message). Fail ho to khali list."""
    try:
        ref = E("GITHUB_REF", "")
        scope = f"&pullRequest={ref.split('/')[2]}" if ref.startswith("refs/pull/") else ""
        url = (f"{server}/api/issues/search?componentKeys={key}&types=VULNERABILITY,BUG"
               f"&resolved=false&ps=20&s=SEVERITY&asc=false{scope}")
        out = []
        for i in http_json(url, token).get("issues", []):
            out.append({"sev": i.get("severity", "?"), "type": i.get("type", "?"),
                        "where": f"{i.get('component', '').split(':')[-1]}:{i.get('line', '?')}",
                        "msg": i.get("message", "")})
        return out
    except Exception:  # noqa: BLE001
        return []


# ------------------------------------------------------------------- trivy
def read_trivy():
    path = "trivy-report/trivy.json"
    if not os.path.exists(path):
        return None
    with open(path) as fh:
        data = json.load(fh)
    vulns = []
    for res in data.get("Results") or []:
        for v in res.get("Vulnerabilities") or []:
            vulns.append(
                {
                    "id": v.get("VulnerabilityID", "?"),
                    "sev": v.get("Severity", "UNKNOWN"),
                    "pkg": v.get("PkgName", "?"),
                    "installed": v.get("InstalledVersion", "?"),
                    "fixed": v.get("FixedVersion", "-"),
                }
            )
    counts = Counter(v["sev"] for v in vulns)
    vulns.sort(key=lambda v: (SEV_ORDER.index(v["sev"]) if v["sev"] in SEV_ORDER else 9, v["id"]))
    return {"counts": counts, "top": vulns[:10], "total": len(vulns)}


def image_size_mb(image):
    try:
        out = subprocess.check_output(
            ["docker", "image", "inspect", "--format", "{{.Size}}", image], text=True, timeout=20, stderr=subprocess.DEVNULL
        )
        return round(int(out.strip()) / 1024 / 1024)
    except Exception:  # noqa: BLE001
        return None


def git_subject():
    try:
        return subprocess.check_output(["git", "log", "-1", "--pretty=%s"], text=True, timeout=10).strip()
    except Exception:  # noqa: BLE001
        return ""


def main():
    image = f"{E('IMAGE_NAME', '?')}:{E('IMAGE_TAG', '?')}"
    run_url = f"{E('GITHUB_SERVER_URL', 'https://github.com')}/{E('GITHUB_REPOSITORY', '')}/actions/runs/{E('GITHUB_RUN_ID', '')}"
    job_status = E("JOB_STATUS", "success")

    tests = trivy = sonar = None
    try:
        tests = read_tests()
    except Exception:  # noqa: BLE001
        pass
    try:
        trivy = read_trivy()
    except Exception:  # noqa: BLE001
        pass
    if outcome("OUT_SONAR") != "skipped":
        sonar = read_sonar()

    slack, md = [], []

    # ---- gitleaks / compile
    for label, var in (("Credential scan (gitleaks)", "OUT_GITLEAKS"), ("Compile", "OUT_COMPILE")):
        o = outcome(var)
        slack.append(f"{ICON.get(o, ':grey_question:')} *{label}:* {WORD.get(o, o)}")
        md.append(f"| {label} | {WORD.get(o, o)} |")

    # ---- unit tests
    o = outcome("OUT_TESTS")
    if tests:
        line = (
            f"{tests['total']} run, {tests['failures']} failed, {tests['errors']} errors, "
            f"{tests['skipped']} skipped ({tests['seconds']:.1f}s)"
        )
    else:
        line = "report nahi mili" if o != "skipped" else "skipped"
    slack.append(f"{ICON.get(o, ':grey_question:')} *Unit tests:* {WORD.get(o, o)} - {line}")
    md.append(f"| Unit tests | {WORD.get(o, o)} - {line} |")

    # ---- sonar
    o = outcome("OUT_SONAR")
    if sonar and sonar.get("gate"):
        m = sonar["measures"]
        gate_ok = sonar["gate"] == "OK"
        detail = (
            f"Quality Gate *{'PASSED' if gate_ok else 'FAILED'}* | bugs {m.get('bugs', '?')} | "
            f"vulnerabilities {m.get('vulnerabilities', '?')} | code smells {m.get('code_smells', '?')} | "
            f"hotspots {m.get('security_hotspots', '?')} | coverage {m.get('coverage', 'n/a')}% | "
            f"duplication {m.get('duplicated_lines_density', '?')}% | {m.get('ncloc', '?')} lines"
        )
        icon = ICON["success"] if gate_ok else ":warning:"
        for c in sonar["conditions"]:
            detail += f"\n      - failed condition: {c.get('metricKey')} ({c.get('actualValue')} vs {c.get('comparator')} {c.get('errorThreshold')})"
        for i in sonar.get("issues", [])[:6]:
            detail += f"\n      - {i['sev']} {i['type']}: `{i['where']}` {i['msg']}"
        slack.append(f"{icon} *SonarCloud:* {detail}\n      <{sonar['dashboard']}|Open Sonar dashboard>")
        md.append(f"| SonarCloud | Quality Gate {sonar['gate']} - [dashboard]({sonar['dashboard']}) |")
    else:
        why = (sonar or {}).get("error") or WORD.get(o, o)
        icon = ":warning:" if (sonar or {}).get("error") else ICON.get(o, ":grey_question:")
        slack.append(f"{icon} *SonarCloud:* {why}")
        md.append(f"| SonarCloud | {why} |")

    # ---- docker build
    o = outcome("OUT_BUILD")
    size = image_size_mb(image) if o == "success" else None
    extra = f"`{image}`" + (f" ({size} MB)" if size else "")
    slack.append(f"{ICON.get(o, ':grey_question:')} *Docker build:* {WORD.get(o, o)} - {extra}")
    md.append(f"| Docker build | {WORD.get(o, o)} - {extra} |")

    # ---- trivy
    o = outcome("OUT_TRIVY")
    if trivy is not None:
        c = trivy["counts"]
        parts = ", ".join(f"{s} {c.get(s, 0)}" for s in ("CRITICAL", "HIGH"))
        icon = ICON["success"] if (c.get("CRITICAL", 0) + c.get("HIGH", 0)) == 0 else ":warning:"
        slack.append(f"{icon} *Trivy image scan (fixable HIGH/CRITICAL):* {parts}")
        for v in trivy["top"][:5]:
            slack.append(f"      - {v['sev']} {v['id']} in `{v['pkg']}` {v['installed']} (fix: {v['fixed']})")
        if trivy["total"] > 5:
            slack.append(f"      - ... and {trivy['total'] - 5} more (full list in run summary / trivy-report artifact)")
        md.append(f"| Trivy | {parts} |")
    else:
        slack.append(f"{ICON.get(o, ':grey_question:')} *Trivy image scan:* {WORD.get(o, o)}")
        md.append(f"| Trivy | {WORD.get(o, o)} |")

    # ---- push
    o = outcome("OUT_PUSH")
    if o == "skipped":
        msg = "skipped (PR par image push nahi hoti)"
    elif o == "success":
        msg = f"pushed `{E('IMAGE_NAME')}` tags `{E('IMAGE_TAG')}` and `latest`"
    else:
        msg = WORD.get(o, o)
    slack.append(f"{ICON.get(o, ':grey_question:')} *Docker push:* {msg}")
    md.append(f"| Docker push | {msg} |")

    subject = slack_escape(git_subject())
    sha = E("GITHUB_SHA", "")[:7]
    head = (
        f"{ICON.get(job_status, ':grey_question:')} *CI Checks {WORD.get(job_status, job_status)}* - {E('GITHUB_REPOSITORY', '')}\n"
        f"*Branch:* {E('GITHUB_REF_NAME', '')} | *Commit:* `{sha}` {subject} | *By:* {E('GITHUB_ACTOR', '')} | *Trigger:* {E('GITHUB_EVENT_NAME', '')}"
    )
    tail = f"*Reports:* <{run_url}|full run + artifacts> (unit-test-report, trivy-report, sonarqube-report, gitleaks)"
    text = head + "\n" + "\n".join(slack) + "\n" + tail

    # ---- step summary (markdown)
    summary = [f"## CI report - `{image}`", "", "| Stage | Result |", "|---|---|", *md, ""]
    if tests and tests["rows"]:
        summary += ["### Unit tests per class", "", "| Class | Tests | Failed | Errors | Skipped | Time (s) |", "|---|---|---|---|---|---|"]
        summary += [f"| {n} | {a} | {b} | {c} | {d} | {t:.2f} |" for n, a, b, c, d, t in tests["rows"]]
        summary.append("")
    if sonar and sonar.get("measures"):
        summary += ["### SonarCloud metrics", "", "| Metric | Value |", "|---|---|"]
        summary += [f"| {k} | {v} |" for k, v in sonar["measures"].items()]
        summary.append("")
    if trivy and trivy["top"]:
        summary += [f"### Trivy: top {len(trivy['top'])} of {trivy['total']} fixable HIGH/CRITICAL", "", "| Severity | CVE | Package | Installed | Fixed in |", "|---|---|---|---|---|"]
        summary += [f"| {v['sev']} | {v['id']} | {v['pkg']} | {v['installed']} | {v['fixed']} |" for v in trivy["top"]]
        summary.append("")

    if E("GITHUB_STEP_SUMMARY"):
        with open(E("GITHUB_STEP_SUMMARY"), "a") as fh:
            fh.write("\n".join(summary) + "\n")
    if E("GITHUB_OUTPUT"):
        delim = "EOF_" + uuid.uuid4().hex
        with open(E("GITHUB_OUTPUT"), "a") as fh:
            fh.write(f"text<<{delim}\n{text}\n{delim}\n")
    else:
        print(text)


if __name__ == "__main__":
    main()
