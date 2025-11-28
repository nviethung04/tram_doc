package handlers

import (
	"net/http"
	"strconv"
	"tram-doc-api/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SocialHandler struct {
	db *gorm.DB
}

func NewSocialHandler(db *gorm.DB) *SocialHandler {
	return &SocialHandler{db: db}
}

// GetFriends returns user's friends list
func (h *SocialHandler) GetFriends(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var friendships []models.Friendship
	if err := h.db.Where("user_id = ? AND status = ?", userID, models.FriendStatusAccepted).
		Preload("Friend").Find(&friendships).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch friends"})
		return
	}

	friends := make([]models.User, len(friendships))
	for i, friendship := range friendships {
		friends[i] = friendship.Friend
		friends[i].Password = "" // Remove password from response
	}

	c.JSON(http.StatusOK, gin.H{
		"friends": friends,
		"count":   len(friends),
	})
}

// AddFriend sends or accepts a friend request
func (h *SocialHandler) AddFriend(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var req struct {
		FriendEmail string `json:"friend_email" binding:"required,email"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find friend by email
	var friend models.User
	if err := h.db.Where("email = ?", req.FriendEmail).First(&friend).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Can't add yourself as friend
	if friend.ID == userID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot add yourself as friend"})
		return
	}

	// Check if friendship already exists
	var existingFriendship models.Friendship
	err := h.db.Where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
		userID, friend.ID, friend.ID, userID).First(&existingFriendship).Error

	if err == nil {
		switch existingFriendship.Status {
		case models.FriendStatusAccepted:
			c.JSON(http.StatusConflict, gin.H{"error": "Already friends"})
			return
		case models.FriendStatusPending:
			// If the other user sent request, accept it
			if existingFriendship.FriendID == userID {
				existingFriendship.Status = models.FriendStatusAccepted
				if err := h.db.Save(&existingFriendship).Error; err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to accept friend request"})
					return
				}
				c.JSON(http.StatusOK, gin.H{"message": "Friend request accepted"})
				return
			} else {
				c.JSON(http.StatusConflict, gin.H{"error": "Friend request already sent"})
				return
			}
		case models.FriendStatusBlocked:
			c.JSON(http.StatusForbidden, gin.H{"error": "Cannot add this user"})
			return
		}
	}

	// Create new friendship
	friendship := models.Friendship{
		UserID:   userID,
		FriendID: friend.ID,
		Status:   models.FriendStatusPending,
	}

	if err := h.db.Create(&friendship).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send friend request"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Friend request sent",
		"friend": gin.H{
			"id":       friend.ID,
			"username": friend.Username,
			"email":    friend.Email,
			"fullname": friend.FullName,
		},
	})
}

// RemoveFriend removes a friend or rejects/cancels friend request
func (h *SocialHandler) RemoveFriend(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	friendID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friend ID"})
		return
	}

	// Find friendship
	var friendship models.Friendship
	if err := h.db.Where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
		userID, uint(friendID), uint(friendID), userID).First(&friendship).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Friendship not found"})
		return
	}

	// Delete friendship
	if err := h.db.Delete(&friendship).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove friend"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Friend removed successfully"})
}

// GetFeed returns activity feed from user's friends
func (h *SocialHandler) GetFeed(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	// Get friend IDs
	var friendships []models.Friendship
	if err := h.db.Where("user_id = ? AND status = ?", userID, models.FriendStatusAccepted).
		Find(&friendships).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch friends"})
		return
	}

	friendIDs := make([]uint, len(friendships))
	for i, friendship := range friendships {
		friendIDs = append(friendIDs, friendship.FriendID)
	}

	// Add user's own ID to see their activities too
	friendIDs = append(friendIDs, userID)

	// Get activities from friends
	var activities []models.Activity
	query := h.db.Where("user_id IN ?", friendIDs).
		Preload("User").
		Preload("Book")

	// Pagination
	limit := 20
	if limitStr := c.Query("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 && parsedLimit <= 100 {
			limit = parsedLimit
		}
	}

	offset := 0
	if offsetStr := c.Query("offset"); offsetStr != "" {
		if parsedOffset, err := strconv.Atoi(offsetStr); err == nil && parsedOffset >= 0 {
			offset = parsedOffset
		}
	}

	if err := query.Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&activities).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch feed"})
		return
	}

	// Remove passwords from user objects
	for i := range activities {
		activities[i].User.Password = ""
	}

	c.JSON(http.StatusOK, gin.H{
		"activities": activities,
		"count":      len(activities),
	})
}

// CreateActivity creates a new activity (used internally by other handlers)
func (h *SocialHandler) CreateActivity(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var req struct {
		BookID  *uint               `json:"book_id"`
		Type    models.ActivityType `json:"type" binding:"required"`
		Content string              `json:"content"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	activity := models.Activity{
		UserID:  userID,
		BookID:  req.BookID,
		Type:    req.Type,
		Content: req.Content,
	}

	if err := h.db.Create(&activity).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create activity"})
		return
	}

	// Load relationships
	h.db.Preload("User").Preload("Book").First(&activity, activity.ID)
	activity.User.Password = ""

	c.JSON(http.StatusCreated, activity)
}

// GetPendingFriendRequests returns pending friend requests
func (h *SocialHandler) GetPendingFriendRequests(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var friendships []models.Friendship
	if err := h.db.Where("friend_id = ? AND status = ?", userID, models.FriendStatusPending).
		Preload("User").Find(&friendships).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch friend requests"})
		return
	}

	requests := make([]gin.H, len(friendships))
	for i, friendship := range friendships {
		friendship.User.Password = ""
		requests[i] = gin.H{
			"id":         friendship.ID,
			"user":       friendship.User,
			"created_at": friendship.CreatedAt,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"requests": requests,
		"count":    len(requests),
	})
}
