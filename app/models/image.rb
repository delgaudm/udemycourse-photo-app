class Image < ActiveRecord::Base
  belongs_to :user
  mount_uploader :picture, PictureUploader
  validate :picture_size
  
  
  private
  def picture_size
    if picture.size > 5.megabytes
      errors.add(:picture, "Image is too large, cannot exceed 5mb")
    end
  end
end
