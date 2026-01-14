import cv2
import numpy as np
import sys

# ================= CONFIGURATION =================
# 1. Path to your TRUSTED High-Quality Reference Crop (e.g., Micro-text region)
REFERENCE_PATH = "reference_microtext.jpg"

# 2. Path to the Incoming Test Frame (The 'Best Frame' from video)
TEST_PATH = "captured_frame.jpg"

# 3. TOLERANCE (How much sharpness loss is allowed?)
# 0.8 means the test image must be at least 80% as sharp as the reference.
SHARPNESS_THRESHOLD_RATIO = 0.6 
# =================================================

def get_sharpness_score(image_path, target_size=(256, 256)):
    img = cv2.imread(image_path)
    if img is None:
        print(f"Error: Could not read {image_path}")
        return None

    
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    
    gray = cv2.resize(gray, target_size)


    score = cv2.Laplacian(gray, cv2.CV_64F).var()
    
    return score

def compare_sharpness():
    print("--- 🔍 SHARPNESS VERIFICATION ---")
    
    # 1. Calculate Scores
    ref_score = get_sharpness_score(REFERENCE_PATH)
    test_score = get_sharpness_score(TEST_PATH)

    if ref_score is None or test_score is None:
        return

    # 2. Calculate Ratio
    # ratio = Test / Real
    ratio = test_score / ref_score

    print(f"Reference Sharpness: {ref_score:.2f}")
    print(f"Test Frame Sharpness: {test_score:.2f}")
    print(f"Sharpness Ratio:      {ratio:.2f} ({(ratio*100):.1f}%)")
    print("-" * 30)

    # 3. The Verdict
    if ratio >= SHARPNESS_THRESHOLD_RATIO:
        print("✅ PASS: The image is sharp (Likely Genuine/Intaglio Print).")
    elif ratio < 0.2:
        print("❌ FAIL: Image is extremely blurry (Out of focus or low res).")
    else:
        print("⚠️ SUSPICIOUS: Image is too soft/smooth compared to real note.")
        print("   (Could be a photocopy or inkjet print)")

if __name__ == "__main__":
    compare_sharpness()