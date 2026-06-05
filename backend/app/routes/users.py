from fastapi import APIRouter, Depends, HTTPException
from ..middleware.auth import get_current_user
from ..database import get_client
from ..models import UserProfile, UserProfileUpdate

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfile)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    db = get_client()
    result = db.table("users").select("*").eq("id", current_user["id"]).single().execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Profil bulunamadı")
    return result.data


@router.put("/me")
async def update_my_profile(
    data: UserProfileUpdate,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()
    update_data = data.model_dump(exclude_none=True)
    update_data["updated_at"] = "now()"

    result = db.table("users").update(update_data).eq("id", current_user["id"]).execute()
    if not result.data:
        raise HTTPException(status_code=500, detail="Profil güncellenemedi")
    return result.data[0]


@router.get("/{user_id}", response_model=UserProfile)
async def get_user_profile(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    db = get_client()
    result = db.table("users").select(
        "id, username, display_name, gender, bio, avatar_url, birth_year, created_at"
    ).eq("id", user_id).single().execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
    return result.data
