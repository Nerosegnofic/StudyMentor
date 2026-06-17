"""
Token-bucket rate limiter for outbound LLM API calls.

Distinct from `app.core.rate_limit` (slowapi), which throttles inbound HTTP
requests. This one is used by background LLM callers (e.g. the mastery refiner)
to stay within provider free-tier limits.
"""
import time
import threading
from typing import List


class RateLimiter:
    """
    Simple token-bucket rate limiter for LLM API calls.
    Gemini 2.5 Flash free tier: 10 RPM, 250K TPM.
    Conservative defaults: max 5 calls/min with a 15s minimum interval.
    """
    def __init__(self, max_calls_per_minute: int = 5, min_interval_seconds: float = 15.0):
        self.max_calls_per_minute = max_calls_per_minute
        self.min_interval_seconds = min_interval_seconds
        self._call_times: List[float] = []
        self._lock = threading.Lock()

    def wait_if_needed(self):
        """Block until it's safe to make the next API call."""
        with self._lock:
            now = time.time()
            # Purge calls older than 60 seconds
            self._call_times = [t for t in self._call_times if now - t < 60]

            # Check RPM limit
            if len(self._call_times) >= self.max_calls_per_minute:
                oldest = self._call_times[0]
                wait_time = 60 - (now - oldest)
                if wait_time > 0:
                    print(f"[RateLimiter] RPM limit reached. Waiting {wait_time:.1f}s...", flush=True)
                    time.sleep(wait_time)
                    now = time.time()
                    self._call_times = [t for t in self._call_times if now - t < 60]

            # Enforce minimum interval between calls
            if self._call_times:
                elapsed = now - self._call_times[-1]
                if elapsed < self.min_interval_seconds:
                    sleep_time = self.min_interval_seconds - elapsed
                    print(f"[RateLimiter] Min interval not met. Waiting {sleep_time:.1f}s...", flush=True)
                    time.sleep(sleep_time)

            self._call_times.append(time.time())