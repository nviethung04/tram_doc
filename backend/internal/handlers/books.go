package handlers

import (
	"net/http"
	"strconv"
	"tram-doc-api/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type BookHandler struct {
	db *gorm.DB
}

func NewBookHandler(db *gorm.DB) *BookHandler {
	return &BookHandler{db: db}
}

type CreateBookRequest struct {
	GoogleID    string            `json:"google_id"`
	ISBN        string            `json:"isbn"`
	Title       string            `json:"title" binding:"required"`
	Authors     string            `json:"authors"`
	Publisher   string            `json:"publisher"`
	PublishDate string            `json:"publish_date"`
	Description string            `json:"description"`
	CoverURL    string            `json:"cover_url"`
	PageCount   int               `json:"page_count"`
	Status      models.BookStatus `json:"status"`
	Location    string            `json:"location"`
}

// GetBooks retrieves all books for the authenticated user
func (h *BookHandler) GetBooks(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var books []models.Book
	query := h.db.Where("user_id = ?", userID)

	// Filter by status if provided
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	// Search by title or author
	if search := c.Query("search"); search != "" {
		query = query.Where("title ILIKE ? OR authors ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	if err := query.Order("created_at DESC").Find(&books).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch books"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"books": books,
		"count": len(books),
	})
}

// CreateBook adds a new book to user's library
func (h *BookHandler) CreateBook(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	var req CreateBookRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if book already exists in user's library
	var existingBook models.Book
	if err := h.db.Where("user_id = ? AND (isbn = ? OR google_id = ?)",
		userID, req.ISBN, req.GoogleID).First(&existingBook).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Book already exists in your library"})
		return
	}

	// Set default status if not provided
	if req.Status == "" {
		req.Status = models.WantToRead
	}

	book := models.Book{
		UserID:      userID,
		GoogleID:    req.GoogleID,
		ISBN:        req.ISBN,
		Title:       req.Title,
		Authors:     req.Authors,
		Publisher:   req.Publisher,
		PublishDate: req.PublishDate,
		Description: req.Description,
		CoverURL:    req.CoverURL,
		PageCount:   req.PageCount,
		Status:      req.Status,
		Location:    req.Location,
	}

	if err := h.db.Create(&book).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create book"})
		return
	}

	// Create activity
	h.createActivity(userID, book.ID, models.ActivityTypeAddBook, "")

	c.JSON(http.StatusCreated, book)
}

// UpdateBook updates book information
func (h *BookHandler) UpdateBook(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	bookID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid book ID"})
		return
	}

	var book models.Book
	if err := h.db.Where("id = ? AND user_id = ?", uint(bookID), userID).First(&book).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Book not found"})
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if status changed to create activity
	oldStatus := book.Status

	if err := h.db.Model(&book).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update book"})
		return
	}

	// Create activity if status changed
	if newStatus, ok := updates["status"]; ok && newStatus != oldStatus {
		switch newStatus {
		case models.Reading:
			h.createActivity(userID, book.ID, models.ActivityTypeStartBook, "")
		case models.Read:
			h.createActivity(userID, book.ID, models.ActivityTypeFinishBook, "")
		}
	}

	// Create activity if rating changed
	if rating, ok := updates["rating"]; ok && rating != nil {
		h.createActivity(userID, book.ID, models.ActivityTypeRateBook, "")
	}

	c.JSON(http.StatusOK, book)
}

// DeleteBook removes a book from user's library
func (h *BookHandler) DeleteBook(c *gin.Context) {
	userID, exists := GetCurrentUserID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	bookID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid book ID"})
		return
	}

	var book models.Book
	if err := h.db.Where("id = ? AND user_id = ?", uint(bookID), userID).First(&book).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Book not found"})
		return
	}

	if err := h.db.Delete(&book).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete book"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Book deleted successfully"})
}

// SearchBooks searches for books using Google Books API (mock for now)
func (h *BookHandler) SearchBooks(c *gin.Context) {
	var req struct {
		Query string `json:"query" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement actual Google Books API integration
	// For now, return mock data
	mockBooks := []map[string]interface{}{
		{
			"google_id":    "mock_id_1",
			"title":        "Sample Book 1",
			"authors":      "Sample Author",
			"publisher":    "Sample Publisher",
			"publish_date": "2023-01-01",
			"description":  "A sample book description",
			"cover_url":    "https://via.placeholder.com/300x400",
			"page_count":   200,
			"isbn":         "1234567890",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"results": mockBooks,
		"query":   req.Query,
	})
}

// ScanBarcode processes barcode scanning results
func (h *BookHandler) ScanBarcode(c *gin.Context) {
	var req struct {
		Barcode string `json:"barcode" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement barcode lookup using Google Books API
	// For now, return mock data
	mockBook := map[string]interface{}{
		"isbn":         req.Barcode,
		"title":        "Scanned Book",
		"authors":      "Barcode Author",
		"publisher":    "Scanned Publisher",
		"publish_date": "2023-01-01",
		"description":  "Book found via barcode scan",
		"cover_url":    "https://via.placeholder.com/300x400",
		"page_count":   250,
	}

	c.JSON(http.StatusOK, gin.H{
		"book":    mockBook,
		"barcode": req.Barcode,
	})
}

// createActivity helper function to create social activities
func (h *BookHandler) createActivity(userID, bookID uint, activityType models.ActivityType, content string) {
	activity := models.Activity{
		UserID:  userID,
		BookID:  bookID,
		Type:    activityType,
		Content: content,
	}
	h.db.Create(&activity)
}
