package main

import (
	"log"
	"tram-doc-api/internal/database"
	"tram-doc-api/internal/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize database
	db, err := database.InitDB()
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Auto migrate models
	err = database.AutoMigrate(db)
	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	// Initialize Gin router
	r := gin.Default()

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db)
	bookHandler := handlers.NewBookHandler(db)
	noteHandler := handlers.NewNoteHandler(db)
	socialHandler := handlers.NewSocialHandler(db)

	// API routes
	api := r.Group("/api")
	{
		// Authentication routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/logout", authHandler.Logout)
		}

		// Protected routes (require authentication)
		protected := api.Group("/")
		protected.Use(authHandler.AuthMiddleware())
		{
			// Books routes
			books := protected.Group("/books")
			{
				books.GET("/", bookHandler.GetBooks)
				books.POST("/", bookHandler.CreateBook)
				books.PUT("/:id", bookHandler.UpdateBook)
				books.DELETE("/:id", bookHandler.DeleteBook)
				books.POST("/search", bookHandler.SearchBooks)
				books.POST("/barcode", bookHandler.ScanBarcode)
			}

			// Notes routes
			notes := protected.Group("/notes")
			{
				notes.GET("/", noteHandler.GetNotes)
				notes.POST("/", noteHandler.CreateNote)
				notes.PUT("/:id", noteHandler.UpdateNote)
				notes.DELETE("/:id", noteHandler.DeleteNote)
				notes.POST("/flashcard", noteHandler.CreateFlashcard)
				notes.GET("/review", noteHandler.GetReviewNotes)
			}

			// Social routes
			social := protected.Group("/social")
			{
				social.GET("/friends", socialHandler.GetFriends)
				social.POST("/friends/add", socialHandler.AddFriend)
				social.DELETE("/friends/:id", socialHandler.RemoveFriend)
				social.GET("/feed", socialHandler.GetFeed)
				social.POST("/activity", socialHandler.CreateActivity)
			}
		}
	}

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"message": "Trạm Đọc API is running",
		})
	})

	log.Println("🚀 Trạm Đọc API server starting on port 8080...")
	r.Run(":8080")
}
