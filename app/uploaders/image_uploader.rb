class ImageUploader < WhitehallUploader
  include CarrierWave::MiniMagick

  configure do |config|
    config.remove_previously_stored_files_after_update = false
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  version :s960 do
    process resize_to_fill: [960, 640]
  end
  version :s712, from_version: :s960 do
    process resize_to_fill: [712, 480]
  end
  version :s630, from_version: :s712 do
    process resize_to_fill: [630, 420]
  end
  version :s465, from_version: :s630 do
    process resize_to_fill: [465, 310]
  end
  version :s300, from_version: :s465 do
    process resize_to_fill: [300, 195]
  end
  version :s216, from_version: :s300 do
    process resize_to_fill: [216, 140]
  end
end
