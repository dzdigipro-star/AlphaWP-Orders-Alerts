"""
Generate Android app icons from a source image.
Creates ic_launcher.png files in all required mipmap directories.
"""
from PIL import Image
import os

# Source image path - the user provided image
SOURCE_IMAGE = r"C:\Users\aflah\.gemini\antigravity\brain\4428fdf4-2445-467a-a6ed-720fae6fabdb\app_icon_1770406297411.png"

# Android icon size requirements
ICON_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Foreground icon for adaptive icons (108dp with 72dp inner icon)
FOREGROUND_SIZE = 432  # 108dp * 4 for xxxhdpi quality

# Base resource directory
RES_DIR = r"c:\Users\aflah\Local Sites\afashop\app\public\wp-content\plugins\AlphaWP-Direct-Checkout\mobile-app\android\app\src\main\res"

def generate_icons():
    # Open source image
    print(f"Opening source image: {SOURCE_IMAGE}")
    if not os.path.exists(SOURCE_IMAGE):
        print(f"ERROR: Source image not found at {SOURCE_IMAGE}")
        return False
    
    img = Image.open(SOURCE_IMAGE)
    
    # Convert to RGBA if necessary
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    print(f"Source image size: {img.size}")
    
    # Generate icons for each mipmap directory
    for folder, size in ICON_SIZES.items():
        output_dir = os.path.join(RES_DIR, folder)
        
        # Create directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Delete existing XML icon if present
        xml_path = os.path.join(output_dir, 'ic_launcher.xml')
        if os.path.exists(xml_path):
            os.remove(xml_path)
            print(f"Removed: {xml_path}")
        
        # Resize and save PNG
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        output_path = os.path.join(output_dir, 'ic_launcher.png')
        resized.save(output_path, 'PNG')
        print(f"Created: {output_path} ({size}x{size})")
    
    # Generate foreground image for adaptive icons (drawable folder)
    # Adaptive icon foreground needs to be 108dp with the icon centered in 72dp area
    drawable_dir = os.path.join(RES_DIR, 'drawable')
    os.makedirs(drawable_dir, exist_ok=True)
    
    # Create a larger canvas with the icon centered for adaptive icon foreground
    # The foreground should be 108dp with padding (72dp safe zone centered)
    foreground_canvas_size = 432  # High quality for xxxhdpi
    icon_size_in_foreground = 288  # 72dp equivalent at xxxhdpi (288 for proper centering)
    
    # Create transparent canvas for foreground
    foreground = Image.new('RGBA', (foreground_canvas_size, foreground_canvas_size), (0, 0, 0, 0))
    
    # Resize icon to fit in the center
    icon_resized = img.resize((icon_size_in_foreground, icon_size_in_foreground), Image.Resampling.LANCZOS)
    
    # Calculate position to center the icon
    offset = (foreground_canvas_size - icon_size_in_foreground) // 2
    foreground.paste(icon_resized, (offset, offset), icon_resized)
    
    # Save foreground PNG
    foreground_path = os.path.join(drawable_dir, 'ic_launcher_foreground.png')
    foreground.save(foreground_path, 'PNG')
    print(f"Created foreground: {foreground_path} ({foreground_canvas_size}x{foreground_canvas_size})")
    
    # Remove old XML foreground if exists
    old_foreground_xml = os.path.join(drawable_dir, 'ic_launcher_foreground.xml')
    if os.path.exists(old_foreground_xml):
        os.remove(old_foreground_xml)
        print(f"Removed: {old_foreground_xml}")
    
    print("\n✓ Icon generation complete!")
    return True

if __name__ == '__main__':
    generate_icons()
