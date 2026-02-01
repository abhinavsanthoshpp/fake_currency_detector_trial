import cv2
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from ultralytics import YOLO

# ---------------- CONFIG ----------------
MODEL_PATH = "best.pt"
VIDEO_SOURCE = "test_video.mp4"      # change to real video to test
TARGET_CLASS = "security_thread"
CONF_THRESH = 0.30

CSV_FILE = "security_thread_optical_analysis.csv"
# --------------------------------------


class OptimalSecurityThreadAnalyzer:

    def __init__(self):
        self.model = YOLO(MODEL_PATH)
        self.records = []
        self.last_bbox = None

        # 🔍 Show model classes once
        print("MODEL CLASSES:", self.model.names)

    def analyze_roi(self, roi):
        if roi.size == 0:
            return None

        hsv = cv2.cvtColor(roi, cv2.COLOR_BGR2HSV)
        h, s, v = cv2.split(hsv)

        # Metallic-ink friendly mask
        mask = (s > 20) & (v > 30)
        if np.count_nonzero(mask) < 15:
            return None

        return (
            float(np.mean(h[mask])),
            float(np.mean(s[mask])),
            float(np.mean(v[mask]))
        )

    def process(self):
        cap = cv2.VideoCapture(VIDEO_SOURCE)
        frame_id = 0

        print("\n🔍 Running security thread analysis...\n")

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            detected_this_frame = False
            results = self.model(frame, verbose=False)

            # ---- YOLO detection ----
            for r in results:
                for box in r.boxes:
                    if box.conf < CONF_THRESH:
                        continue

                    class_name = self.model.names[int(box.cls[0])]
                    if class_name != TARGET_CLASS:
                        continue

                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    self.last_bbox = (x1, y1, x2, y2)
                    detected_this_frame = True
                    break

            # ---- Persist bbox if YOLO flickers ----
            if not detected_this_frame and self.last_bbox is not None:
                x1, y1, x2, y2 = self.last_bbox
                detected_this_frame = True

            if detected_this_frame:
                roi = frame[y1:y2, x1:x2]
                metrics = self.analyze_roi(roi)

                if metrics is not None:
                    h, s, v = metrics
                    self.records.append([frame_id, h, s, v])

                    print(f"Frame {frame_id:04d} | H={h:.2f} S={s:.2f} V={v:.2f}")

                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(
                        frame,
                        f"H:{int(h)} S:{int(s)} V:{int(v)}",
                        (x1, y1 - 8),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.45,
                        (0, 255, 0),
                        1
                    )

            # ---- Show record count ----
            cv2.putText(
                frame,
                f"Records: {len(self.records)}",
                (20, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                (0, 255, 255),
                2
            )

            cv2.imshow("Security Thread Detection + Analysis", frame)
            frame_id += 1

            if cv2.waitKey(1) & 0xFF == ord("q"):
                break

        cap.release()
        cv2.destroyAllWindows()
        self.verdict()

    def verdict(self):
        print("\n================ FINAL REPORT ================\n")

        if len(self.records) < 10:
            print("❌ Not enough data collected.")
            return

        df = pd.DataFrame(
            self.records,
            columns=["Frame", "Hue", "Saturation", "Value"]
        )

        df.to_csv(CSV_FILE, index=False)
        print(f"✅ Records saved: {CSV_FILE}")
        print(f"Total frames analyzed: {len(df)}\n")

        # ---- Optical metrics ----
        sat_var = df["Saturation"].max() - df["Saturation"].min()
        val_var = df["Value"].max() - df["Value"].min()
        hue_min = df["Hue"].min()
        hue_max = df["Hue"].max()
        hue_range = hue_max - hue_min
        hue_std = df["Hue"].std()

        print("--- METRICS ---")
        print(f"Hue range:        {hue_min:.1f} → {hue_max:.1f} (Δ={hue_range:.1f})")
        print(f"Hue std dev:      {hue_std:.2f}")
        print(f"Saturation range:{sat_var:.2f}")
        print(f"Brightness range:{val_var:.2f}\n")

        # ---- FINAL DECISION (FIXED LOGIC) ----
        if (
            sat_var > 18 and
            val_var > 15 and
            hue_range > 12 and      # must really change color
            hue_max > 85 and        # must enter blue/cyan
            hue_std > 3             # reject flat green strips
        ):
            verdict = "✅ AUTHENTIC (Optical + chromatic shift detected)"

        elif (
            sat_var > 12 and
            val_var > 10 and
            hue_range > 6
        ):
            verdict = "⚠️ LIKELY AUTHENTIC (Weak optical response)"

        else:
            verdict = "❌ STATIC / PRINTED INK (FAKE)"

        print("FINAL VERDICT:", verdict)

        # ---- Plot ----
        df.plot(
            x="Frame",
            y=["Hue", "Saturation", "Value"],
            figsize=(10, 5),
            title="Security Thread Optical & Chromatic Behaviour"
        )
        plt.grid(alpha=0.3)
        plt.show()


if __name__ == "__main__":
    OptimalSecurityThreadAnalyzer().process()
