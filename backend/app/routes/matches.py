from fastapi import APIRouter, Depends, HTTPException
from ..middleware.auth import get_current_user
from ..database import get_client
from ..models import MessageCreate, MessageResponse
from typing import List

router = APIRouter(prefix="/matches", tags=["matches"])


@router.get("")
async def get_my_matches(current_user: dict = Depends(get_current_user)):
    db = get_client()
    uid = current_user["id"]

    result = db.table("matches").select(
        "*, user1:users!matches_user1_id_fkey(id,username,display_name,avatar_url), "
        "user2:users!matches_user2_id_fkey(id,username,display_name,avatar_url)"
    ).or_(f"user1_id.eq.{uid},user2_id.eq.{uid}").eq("status", "active").execute()

    matches = []
    for m in result.data:
        other = m["user2"] if m["user1_id"] == uid else m["user1"]
        matches.append({
            "id": m["id"],
            "status": m["status"],
            "capsule_id": m["capsule_id"],
            "created_at": m["created_at"],
            "other_user": other,
        })
    return matches


@router.get("/{match_id}/messages", response_model=List[MessageResponse])
async def get_messages(
    match_id: str,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()

    # Eşleşme bu kullanıcıya ait mi?
    match = db.table("matches").select("id").eq("id", match_id).or_(
        f"user1_id.eq.{current_user['id']},user2_id.eq.{current_user['id']}"
    ).execute()

    if not match.data:
        raise HTTPException(status_code=403, detail="Bu eşleşmeye erişim yok")

    result = db.table("messages").select("*").eq("match_id", match_id).order(
        "created_at", desc=False
    ).execute()

    # Okunmamış mesajları okundu yap
    db.table("messages").update({"is_read": True}).eq("match_id", match_id).neq(
        "sender_id", current_user["id"]
    ).eq("is_read", False).execute()

    return result.data


@router.post("/{match_id}/messages")
async def send_message(
    match_id: str,
    data: MessageCreate,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()
    result = db.table("messages").insert({
        "match_id": match_id,
        "sender_id": current_user["id"],
        "content": data.content,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Mesaj gönderilemedi")
    return result.data[0]
