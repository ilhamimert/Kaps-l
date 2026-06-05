from fastapi import APIRouter, Depends, HTTPException, status, Query
from ..middleware.auth import get_current_user
from ..database import get_client
from ..models import CapsuleCreate, CapsuleResponse, UnlockCreate
from typing import List

router = APIRouter(prefix="/capsules", tags=["capsules"])


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_capsule(
    data: CapsuleCreate,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()
    result = db.table("capsules").insert({
        "user_id": current_user["id"],
        "location": f"SRID=4326;POINT({data.longitude} {data.latitude})",
        "is_indoor": data.is_indoor,
        "content_text": data.content_text,
        "song_name": data.song_name,
        "artist_name": data.artist_name,
        "mood": data.mood,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Kapsül oluşturulamadı")
    return {"id": result.data[0]["id"], "message": "Kapsül bırakıldı"}


@router.get("/nearby", response_model=List[CapsuleResponse])
async def get_nearby_capsules(
    lat: float = Query(..., ge=-90, le=90),
    lon: float = Query(..., ge=-180, le=180),
    current_user: dict = Depends(get_current_user),
):
    db = get_client()
    result = db.rpc("get_nearby_capsules", {
        "user_lat": lat,
        "user_lon": lon,
        "limit_count": 50,
    }).execute()

    # Kendi kapsüllerini filtrele
    capsules = [c for c in result.data if c["user_id"] != current_user["id"]]
    return capsules


@router.post("/unlock", status_code=status.HTTP_201_CREATED)
async def unlock_capsule(
    data: UnlockCreate,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()

    # Daha önce açılmış mı kontrol et
    existing = db.table("capsule_unlocks").select("id").eq(
        "capsule_id", str(data.capsule_id)
    ).eq("opener_id", current_user["id"]).execute()

    if existing.data:
        # Cevap güncelle
        db.table("capsule_unlocks").update({"reply_text": data.reply_text}).eq(
            "id", existing.data[0]["id"]
        ).execute()
        return {"message": "Cevap güncellendi"}

    # İlk kez açılıyor
    result = db.table("capsule_unlocks").insert({
        "capsule_id": str(data.capsule_id),
        "opener_id": current_user["id"],
        "reply_text": data.reply_text,
    }).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Kapsül açılamadı")
    return {"message": "Kapsül açıldı", "unlock_id": result.data[0]["id"]}


@router.get("/my")
async def get_my_capsules(current_user: dict = Depends(get_current_user)):
    db = get_client()
    result = db.table("capsules").select("*").eq(
        "user_id", current_user["id"]
    ).order("created_at", desc=True).execute()
    return result.data


@router.delete("/{capsule_id}")
async def delete_capsule(
    capsule_id: str,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()
    result = db.table("capsules").update({"is_active": False}).eq(
        "id", capsule_id
    ).eq("user_id", current_user["id"]).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Kapsül bulunamadı")
    return {"message": "Kapsül silindi"}
