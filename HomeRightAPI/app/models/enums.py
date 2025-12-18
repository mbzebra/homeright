from enum import Enum


class Schedule(str, Enum):
    monthly = "monthly"
    quarterly = "quarterly"
    seasonal = "seasonal"
    annual = "annual"
    spring = "spring"
    summer = "summer"
    fall = "fall"
    winter = "winter"
    custom = "custom"


class TaskStatus(str, Enum):
    not_started = "not_started"
    in_progress = "in_progress"
    complete = "complete"

