require "pathname"
require "fileutils"
require Pathname(__FILE__).dirname.parent + "helper"

class ImageTest < Test::Unit::TestCase

  def test_reading_data_without_category
    meta = Fmeta::Image.new(SAMPLE_PATH)

    assert_equal("320", meta['ImageWidth'])
    assert_equal("12", meta['PhotoshopQuality'])
    assert_equal("Lead Smiley Designer", meta['AuthorsPosition'])
    assert_equal("Smiley's Debut", meta['Caption-Abstract'])
    assert_equal(DateTime.parse("2009-12-06 20:28:48"), meta['ModifyDate'])
    assert_equal(DateTime.parse("2009-12-06 20:28:48-06:00"), meta['MetadataDate'])

    assert_equal(nil, meta['Some Nonexistent Tag'])
  end

  def test_reading_data_with_category
    meta = Fmeta::Image.new(SAMPLE_PATH)

    assert_equal("320", meta['File:ImageWidth'])
    assert_equal("12", meta['Photoshop:PhotoshopQuality'])
    assert_equal("Lead Smiley Designer", meta['XMP:AuthorsPosition'])
    assert_equal("Smiley's Debut", meta['IPTC:Caption-Abstract'])
    assert_equal(DateTime.parse("2009-12-06 20:28:48"), meta['EXIF:ModifyDate'])
    assert_equal(DateTime.parse("2009-12-06 20:28:48-06:00"), meta['XMP:MetadataDate'])

    assert_equal(nil, meta['XMP:Some Nonexistent Tag'])
    assert_equal(nil, meta['EXIF:MetadataDate'])
    assert_equal(nil, meta['EXIF:Caption-Abstract'])
  end

  def test_writing_data_without_category
    tempfile = Tempfile.new('fmeta')
    FileUtils.cp(SAMPLE_PATH, tempfile.path)
    metadata_date = DateTime.now

    # Write new metadata
    meta = Fmeta::Image.new(tempfile.path)
    meta['AuthorsPosition'] = "Director of Smiley Design"
    meta['MetadataDate'] = metadata_date
    meta['Caption-Abstract'] = ''
    meta['Subject'] = nil
    meta.save

    # Ensure that the changes were persisted
    meta = Fmeta::Image.new(tempfile.path)

    assert_equal("Director of Smiley Design", meta['AuthorsPosition'])
    assert_equal(metadata_date.to_s, meta['MetadataDate'].to_s)
    assert_equal(nil, meta['Caption-Abstract'])
    assert_equal(nil, meta['Subject'])

    FileUtils.rm(tempfile.path)
  end

  def test_file_permissions_persist
    original_permissions = File.stat(SAMPLE_PATH).mode

    writer = Fmeta::Image::Exiftool::Writer.new(SAMPLE_PATH)
    dirty_tags = []
    writer.write(dirty_tags)

    assert_equal(original_permissions, File.stat(SAMPLE_PATH).mode)
  end

  def test_writing_data_with_bad_date
    tempfile = Tempfile.new('fmeta')
    FileUtils.cp(SAMPLE_PATH, tempfile.path)
    bad_date = "0000:00:00 00:00:00+00:00"

    # Write new metadata
    meta = Fmeta::Image.new(tempfile.path)
    meta['MetadataDate'] = bad_date
    meta.save

    # Ensure that the changes were persisted
    meta = Fmeta::Image.new(tempfile.path)

    assert_equal("0000:00:00 00:00:00+00:00", meta['MetadataDate'].to_s)

    FileUtils.rm(tempfile.path)
  end

end