package handlers

import (
	"math"
	"net/http"
	"strconv"
	"time"
	"tram-doc-api/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type NoteHandler struct {
	db *gorm.DB
}

func NewNoteHandler(db *gorm.DB) *NoteHandler {
	return &NoteHandler{db: db}
}

type CreateNoteRequest struct {
	BookID  uint            `json:"book_id" binding:"required"`
	Content string          `json:"content" binding:"required"`
	Page    int             `json:"page"`
	Type    models.NoteType `json:"type"`
}

// GetNotes retrieves notes for the authenticated user
func (h *NoteHandler) GetNotes(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var notes []models.Note
	query := h.db.Where("user_id = ?", userID).Preload("Book")

	// Filter by book ID if provided
	if bookIDStr := c.Query("book_id"); bookIDStr != "" {
		if bookID, err := strconv.ParseUint(bookIDStr, 10, 32); err == nil {
			query = query.Where("book_id = ?", uint(bookID))
		}
	}

	// Filter by note type
	if noteType := c.Query("type"); noteType != "" {
		query = query.Where("type = ?", noteType)
	}

	// Search in content
	if search := c.Query("search"); search != "" {
		query = query.Where("content ILIKE ?", "%"+search+"%")
	}

	if err := query.Order("created_at DESC").Find(&notes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notes"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"notes": notes,
		"count": len(notes),
	})
}

// CreateNote adds a new note
func (h *NoteHandler) CreateNote(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var req CreateNoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify book belongs to user
	var book models.Book
	if err := h.db.Where("id = ? AND user_id = ?", req.BookID, userID).First(&book).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Book not found"})
		return
	}

	// Set default type if not provided
	if req.Type == "" {
		req.Type = models.NoteTypeNote
	}

	note := models.Note{
		UserID:  userID,
		BookID:  req.BookID,
		Content: req.Content,
		Page:    req.Page,
		Type:    req.Type,
	}

	if err := h.db.Create(&note).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create note"})
		return
	}

	// Preload book information
	h.db.Preload("Book").First(&note, note.ID)

	// Create activity
	h.createNoteActivity(userID, req.BookID, models.ActivityTypeAddNote, "")

	c.JSON(http.StatusCreated, note)
}

// UpdateNote updates an existing note
func (h *NoteHandler) UpdateNote(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	noteID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid note ID"})
		return
	}

	var note models.Note
	if err := h.db.Where("id = ? AND user_id = ?", uint(noteID), userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Note not found"})
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.db.Model(&note).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update note"})
		return
	}

	c.JSON(http.StatusOK, note)
}

// DeleteNote removes a note
func (h *NoteHandler) DeleteNote(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	noteID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid note ID"})
		return
	}

	var note models.Note
	if err := h.db.Where("id = ? AND user_id = ?", uint(noteID), userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Note not found"})
		return
	}

	if err := h.db.Delete(&note).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete note"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Note deleted successfully"})
}

// CreateFlashcard converts a note into a flashcard for spaced repetition
func (h *NoteHandler) CreateFlashcard(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var req struct {
		NoteID uint `json:"note_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find and verify note
	var note models.Note
	if err := h.db.Where("id = ? AND user_id = ?", req.NoteID, userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Note not found"})
		return
	}

	// Convert to flashcard
	now := time.Now()
	nextReview := now.Add(time.Hour * 24) // Review tomorrow

	updates := map[string]interface{}{
		"is_flashcard": true,
		"next_review":  &nextReview,
		"ease":         2.5,
		"interval":     1,
		"review_count": 0,
	}

	if err := h.db.Model(&note).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create flashcard"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "Flashcard created successfully",
		"next_review": nextReview,
	})
}

// GetReviewNotes returns notes that are due for review (spaced repetition)
func (h *NoteHandler) GetReviewNotes(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var notes []models.Note
	now := time.Now()

	if err := h.db.Where("user_id = ? AND is_flashcard = ? AND next_review <= ?",
		userID, true, now).
		Preload("Book").
		Order("next_review ASC").
		Find(&notes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch review notes"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"notes": notes,
		"count": len(notes),
	})
}

// ReviewFlashcard processes user's review of a flashcard (spaced repetition algorithm)
func (h *NoteHandler) ReviewFlashcard(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	noteID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid note ID"})
		return
	}

	var req struct {
		Quality int `json:"quality" binding:"required,min=0,max=5"` // 0-5 scale
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var note models.Note
	if err := h.db.Where("id = ? AND user_id = ? AND is_flashcard = ?",
		uint(noteID), userID, true).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Flashcard not found"})
		return
	}

	// Apply spaced repetition algorithm (simplified SM-2)
	ease := note.Ease
	interval := note.Interval
	reviewCount := note.ReviewCount + 1

	if req.Quality >= 3 {
		// Correct response
		if reviewCount == 1 {
			interval = 1
		} else if reviewCount == 2 {
			interval = 6
		} else {
			interval = int(math.Round(float64(interval) * ease))
		}
		ease = ease + (0.1 - (5-float64(req.Quality))*(0.08+(5-float64(req.Quality))*0.02))
	} else {
		// Incorrect response - reset interval
		reviewCount = 0
		interval = 1
	}

	// Ensure ease doesn't go below 1.3
	if ease < 1.3 {
		ease = 1.3
	}

	// Calculate next review date
	nextReview := time.Now().Add(time.Hour * 24 * time.Duration(interval))

	// Update note
	updates := map[string]interface{}{
		"review_count": reviewCount,
		"next_review":  &nextReview,
		"ease":         ease,
		"interval":     interval,
	}

	if err := h.db.Model(&note).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update flashcard"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Review recorded successfully",
		"next_review":  nextReview,
		"interval":     interval,
		"ease":         ease,
		"review_count": reviewCount,
	})
}

// createNoteActivity helper function to create activities
func (h *NoteHandler) createNoteActivity(userID, bookID uint, activityType models.ActivityType, content string) {
	activity := models.Activity{
		UserID:  userID,
		BookID:  bookID,
		Type:    activityType,
		Content: content,
	}
	h.db.Create(&activity)
}
