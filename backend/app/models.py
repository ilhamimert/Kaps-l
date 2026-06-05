from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID


class UserProfile(BaseModel):
    id: UUID
    username: str
    display_name: Optional[str] = None
    gender: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    birth_year: Optional[int] = None
    created_at: datetime


class UserProfileUpdate(BaseModel):
    display_name: Optional[str] = Field(None, max_length=100)
    gender: Optional[str] = Field(None, pattern="^(male|female|other)$")
    bio: Optional[str] = Field(None, max_length=300)
    birth_year: Optional[int] = Field(None, ge=1920, le=2010)


class CapsuleCreate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    is_indoor: bool = False
    content_text: str = Field(..., min_length=1, max_length=300)
    song_name: Optional[str] = Field(None, max_length=100)
    artist_name: Optional[str] = Field(None, max_length=100)
    mood: Optional[str] = Field(
        None,
        pattern="^(happy|sad|excited|calm|nostalgic|romantic|curious)$"
    )


class CapsuleResponse(BaseModel):
    id: UUID
    user_id: UUID
    content_text: str
    song_name: Optional[str] = None
    artist_name: Optional[str] = None
    mood: Optional[str] = None
    is_indoor: bool
    unlock_count: int
    distance_meters: float
    created_at: datetime


class UnlockCreate(BaseModel):
    capsule_id: UUID
    reply_text: Optional[str] = Field(None, max_length=300)


class MessageCreate(BaseModel):
    match_id: UUID
    content: str = Field(..., min_length=1, max_length=1000)


class MessageResponse(BaseModel):
    id: UUID
    match_id: UUID
    sender_id: UUID
    content: str
    is_read: bool
    created_at: datetime


class MatchResponse(BaseModel):
    id: UUID
    user1_id: UUID
    user2_id: UUID
    capsule_id: Optional[UUID] = None
    status: str
    created_at: datetime
    other_user: Optional[UserProfile] = None
