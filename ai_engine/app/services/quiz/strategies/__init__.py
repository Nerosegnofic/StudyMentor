from .profile import SubjectProfile
from .math import PROFILE as MATH
from .english import PROFILE as ENGLISH
from .arabic import PROFILE as ARABIC
from .science import PROFILE as SCIENCE
from .social_studies import PROFILE as SOCIAL_STUDIES
from .general import PROFILE as GENERAL

# Fallback for any unrecognized subject.
DEFAULT_PROFILE = GENERAL

__all__ = [
    "SubjectProfile",
    "MATH",
    "ENGLISH",
    "ARABIC",
    "SCIENCE",
    "SOCIAL_STUDIES",
    "GENERAL",
    "DEFAULT_PROFILE",
]