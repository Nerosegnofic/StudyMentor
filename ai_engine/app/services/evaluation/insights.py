"""
Parent insight & alert rules engine (Reports → Overview).

Pure functions (no DB, no LLM): they turn a dict of precomputed weekly signals
into (a) a prioritized list of actionable alerts and (b) a short natural-language
summary. Thresholds come from `settings` so they stay tunable in one place.
"""
from app.core.config import settings

_SEVERITY_ORDER = {"high": 0, "medium": 1, "info": 2}


def build_alerts(signals: dict) -> list:
    """Return up to 4 alerts (highest severity first) from the weekly signals."""
    alerts = []

    days_since = signals.get("days_since_last_quiz")
    if days_since is not None and days_since >= settings.INSIGHT_INACTIVITY_DAYS:
        alerts.append({
            "severity": "high",
            "type": "inactivity",
            "message": f"No quizzes in {days_since} days — the study streak is at risk.",
        })

    acc_delta = signals.get("accuracy_delta")
    if acc_delta is not None and acc_delta <= -settings.INSIGHT_ACCURACY_DROP_PERCENT:
        alerts.append({
            "severity": "high",
            "type": "accuracy_drop",
            "message": f"Accuracy fell {abs(round(acc_delta))}% from last week.",
        })

    accuracy = signals.get("accuracy", 0.0)
    if signals.get("total_quizzes", 0) > 0 and accuracy < settings.INSIGHT_LOW_ACCURACY_PERCENT:
        alerts.append({
            "severity": "medium",
            "type": "low_accuracy",
            "message": f"Accuracy is {round(accuracy)}% this week — time to review weak topics.",
        })

    guessing = signals.get("guessing_sessions", 0)
    if guessing > 0:
        alerts.append({
            "severity": "medium",
            "type": "guessing",
            "message": f"{guessing} quiz{'zes' if guessing > 1 else ''} showed rapid guessing.",
        })

    weak = signals.get("weakest_subject")
    if weak and weak["mastery"] < settings.WEAK_SUBJECT_MASTERY_PERCENT:
        alerts.append({
            "severity": "medium",
            "type": "weak_subject",
            "message": f"{weak['name']} mastery is {round(weak['mastery'])}% — needs attention.",
        })

    alerts.sort(key=lambda a: _SEVERITY_ORDER.get(a["severity"], 3))
    return alerts[:4]


_DAILY_SEVERITY_ORDER = {"high": 0, "warn": 1, "good": 2, "info": 3}


def _daily_child_slide(child: dict) -> dict:
    """One per-child slide {child_uid, text, severity} for the parent home summary."""
    name = child["name"]
    uid = child["child_uid"]
    quizzes = child.get("quizzes_today", 0)

    if quizzes == 0:
        days = child.get("days_since_last_quiz")
        if days is not None and days >= settings.INSIGHT_INACTIVITY_DAYS:
            return {
                "child_uid": uid,
                "severity": "high",
                "text": f"{name} hasn't studied in {days} days — a nudge would help.",
            }
        return {
            "child_uid": uid,
            "severity": "warn",
            "text": f"{name} hasn't studied yet today — a quick session keeps the streak alive.",
        }

    accuracy = round(child.get("accuracy_today", 0))
    streak = child.get("current_streak", 0)
    weak = child.get("weakest_subject")

    text = f"{name} completed {quizzes} quiz{'zes' if quizzes > 1 else ''} today at {accuracy}%"
    if streak >= 3:
        text += f", keeping a {streak}-day streak"
    text += "."

    severity = "good"
    if weak and weak["mastery"] < settings.WEAK_SUBJECT_MASTERY_PERCENT:
        text += f" {weak['name']} still needs work ({round(weak['mastery'])}%)."
        if accuracy < settings.INSIGHT_LOW_ACCURACY_PERCENT:
            severity = "warn"
    elif accuracy < settings.INSIGHT_LOW_ACCURACY_PERCENT:
        severity = "warn"

    return {"child_uid": uid, "severity": severity, "text": text}


def _daily_household_headline(children: list) -> dict:
    """A single household overview slide for parents with multiple children."""
    n = len(children)
    studied = sum(1 for c in children if c.get("quizzes_today", 0) > 0)
    parts = [f"{studied} of {n} kids studied today."]
    severity = "info"

    best = max(children, key=lambda c: c.get("current_streak", 0))
    if best.get("current_streak", 0) >= 3:
        parts.append(f"{best['name']} has the best streak ({best['current_streak']} days).")

    inactive = [
        c["name"]
        for c in children
        if (c.get("days_since_last_quiz") or 0) >= settings.INSIGHT_INACTIVITY_DAYS
    ]
    if inactive:
        parts.append(f"{', '.join(inactive)} hasn't studied in a while.")
        severity = "warn"

    return {"child_uid": None, "severity": severity, "text": " ".join(parts)}


def build_daily_summary(children: list) -> list:
    """
    Build the parent-home daily summary slides from per-child signals:
    a household headline (only with 2+ children) followed by one slide per child,
    most-needs-attention first.
    """
    if not children:
        return [{
            "child_uid": None,
            "severity": "info",
            "text": "Add a child to start seeing daily summaries.",
        }]

    child_slides = [_daily_child_slide(c) for c in children]
    child_slides.sort(key=lambda s: _DAILY_SEVERITY_ORDER.get(s["severity"], 4))

    slides = []
    if len(children) >= 2:
        slides.append(_daily_household_headline(children))
    slides.extend(child_slides)
    return slides


def build_insight(signals: dict) -> str:
    """Return a short, prioritized weekly summary sentence (English)."""
    quizzes = signals.get("total_quizzes", 0)
    if quizzes == 0:
        return (
            "No quizzes completed this week yet. A short session would restart the "
            "streak and keep momentum going."
        )

    accuracy = round(signals.get("accuracy", 0.0))
    acc_delta = signals.get("accuracy_delta")
    streak = signals.get("current_streak", 0)
    guessing = signals.get("guessing_sessions", 0)
    weak = signals.get("weakest_subject")

    parts = []

    # Lead with performance vs. last week.
    if acc_delta is not None and acc_delta >= 2:
        parts.append(
            f"Accuracy climbed {round(acc_delta)}% to {accuracy}% across {quizzes} quizzes this week."
        )
    elif acc_delta is not None and acc_delta <= -2:
        parts.append(
            f"Accuracy slipped {abs(round(acc_delta))}% to {accuracy}% across {quizzes} quizzes this week."
        )
    else:
        parts.append(f"Accuracy held around {accuracy}% across {quizzes} quizzes this week.")

    # Consistency.
    if streak >= 3:
        parts.append(f"A {streak}-day study streak shows great consistency.")

    # One concern to act on.
    if guessing > 0:
        parts.append(
            f"Watch for rushing — {guessing} quiz{'zes' if guessing > 1 else ''} showed rapid guessing."
        )
    elif weak and weak["mastery"] < settings.WEAK_SUBJECT_MASTERY_PERCENT:
        parts.append(
            f"{weak['name']} is the weak spot at {round(weak['mastery'])}% — a focused session there would help most."
        )

    return " ".join(parts)