class Book < ApplicationRecord
    require 'carrierwave/orm/activerecord'
    mount_uploader :cover_image, AvatarUploader
    belongs_to :library
    has_many :book_issue_history, dependent: :destroy
    has_many :hold_requests

    validates :title , presence: true
    validates :isbn , presence: true
    validates :author , presence: true
    validates :language , presence: true
    validates :library_id,presence: true
    validates :published , presence: true
    validates :edition , presence: true, numericality: { greater_than_or_equal_to: 1 }
    validates :quantity, presence: true
    validates :cover_image , presence: true
    validates :subject , presence: true
    validates :summary , presence: true
    validates_inclusion_of :special_collection, :in => [true, false]

end
