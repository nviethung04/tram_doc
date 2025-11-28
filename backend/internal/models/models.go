package models

import (
	"time"

	"gorm.io/gorm"
)

// User represents a user in the system
type User struct {
	ID        uint           `json:"id" gorm:"primarykey"`
	Email     string         `json:"email" gorm:"unique;not null"`
	Username  string         `json:"username" gorm:"unique;not null"`
	Password  string         `json:"-" gorm:"not null"`
	FullName  string         `json:"full_name"`
	Avatar    string         `json:"avatar"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Books      []Book     `json:"books" gorm:"foreignKey:UserID"`
	Notes      []Note     `json:"notes" gorm:"foreignKey:UserID"`
	Friends    []User     `json:"friends" gorm:"many2many:user_friends;"`
	Activities []Activity `json:"activities" gorm:"foreignKey:UserID"`
}

// Book represents a book in user's library
type Book struct {
	ID          uint           `json:"id" gorm:"primarykey"`
	UserID      uint           `json:"user_id" gorm:"not null"`
	GoogleID    string         `json:"google_id"`
	ISBN        string         `json:"isbn"`
	Title       string         `json:"title" gorm:"not null"`
	Authors     string         `json:"authors"`
	Publisher   string         `json:"publisher"`
	PublishDate string         `json:"publish_date"`
	Description string         `json:"description"`
	CoverURL    string         `json:"cover_url"`
	PageCount   int            `json:"page_count"`
	Status      BookStatus     `json:"status" gorm:"type:varchar(20);default:'want_to_read'"`
	Progress    int            `json:"progress" gorm:"default:0"`
	Location    string         `json:"location"` // For physical books
	Rating      int            `json:"rating" gorm:"check:rating >= 0 AND rating <= 5"`
	StartDate   *time.Time     `json:"start_date"`
	FinishDate  *time.Time     `json:"finish_date"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	User  User   `json:"user" gorm:"foreignKey:UserID"`
	Notes []Note `json:"notes" gorm:"foreignKey:BookID"`
}

// BookStatus enum
type BookStatus string

const (
	WantToRead BookStatus = "want_to_read"
	Reading    BookStatus = "reading"
	Read       BookStatus = "read"
)

// Note represents a note/highlight from a book
type Note struct {
	ID          uint           `json:"id" gorm:"primarykey"`
	UserID      uint           `json:"user_id" gorm:"not null"`
	BookID      uint           `json:"book_id" gorm:"not null"`
	Content     string         `json:"content" gorm:"not null"`
	Page        int            `json:"page"`
	Type        NoteType       `json:"type" gorm:"type:varchar(20);default:'note'"`
	IsFlashcard bool           `json:"is_flashcard" gorm:"default:false"`
	ReviewCount int            `json:"review_count" gorm:"default:0"`
	NextReview  *time.Time     `json:"next_review"`
	Ease        float64        `json:"ease" gorm:"default:2.5"`
	Interval    int            `json:"interval" gorm:"default:0"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	User User `json:"user" gorm:"foreignKey:UserID"`
	Book Book `json:"book" gorm:"foreignKey:BookID"`
}

// NoteType enum
type NoteType string

const (
	NoteTypeNote      NoteType = "note"
	NoteTypeHighlight NoteType = "highlight"
	NoteTypeQuote     NoteType = "quote"
	NoteTypeTakeaway  NoteType = "takeaway"
)

// Activity represents social activities
type Activity struct {
	ID        uint           `json:"id" gorm:"primarykey"`
	UserID    uint           `json:"user_id" gorm:"not null"`
	BookID    uint           `json:"book_id"`
	Type      ActivityType   `json:"type" gorm:"not null"`
	Content   string         `json:"content"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	User User  `json:"user" gorm:"foreignKey:UserID"`
	Book *Book `json:"book" gorm:"foreignKey:BookID"`
}

// ActivityType enum
type ActivityType string

const (
	ActivityTypeAddBook    ActivityType = "add_book"
	ActivityTypeFinishBook ActivityType = "finish_book"
	ActivityTypeRateBook   ActivityType = "rate_book"
	ActivityTypeAddNote    ActivityType = "add_note"
	ActivityTypeStartBook  ActivityType = "start_book"
)

// Friendship represents friendship between users
type Friendship struct {
	ID        uint           `json:"id" gorm:"primarykey"`
	UserID    uint           `json:"user_id" gorm:"not null"`
	FriendID  uint           `json:"friend_id" gorm:"not null"`
	Status    FriendStatus   `json:"status" gorm:"type:varchar(20);default:'pending'"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	User   User `json:"user" gorm:"foreignKey:UserID"`
	Friend User `json:"friend" gorm:"foreignKey:FriendID"`
}

// FriendStatus enum
type FriendStatus string

const (
	FriendStatusPending  FriendStatus = "pending"
	FriendStatusAccepted FriendStatus = "accepted"
	FriendStatusBlocked  FriendStatus = "blocked"
)
