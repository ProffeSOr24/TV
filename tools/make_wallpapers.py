"""Генерирует обои 1920x1080 для Projectivy Launcher: тёмный фон с мягкими цветными пятнами."""
import numpy as np
from PIL import Image, ImageFilter
from pathlib import Path

W, H = 1920, 1080
OUT = Path(__file__).resolve().parent.parent / "wallpapers"

# (имя, цвет фона, [(x, y, радиус, цвет), ...]) — координаты в долях экрана
THEMES = [
    ("aurora", (8, 10, 20), [(0.15, 0.2, 0.55, (40, 200, 170)), (0.8, 0.1, 0.5, (90, 60, 220)), (0.6, 0.95, 0.45, (20, 90, 200))]),
    ("sunset", (18, 8, 16), [(0.1, 0.9, 0.6, (240, 100, 60)), (0.85, 0.2, 0.5, (200, 40, 120)), (0.45, 0.5, 0.35, (250, 170, 80))]),
    ("ocean",  (4, 12, 22), [(0.2, 0.8, 0.6, (0, 120, 200)), (0.9, 0.7, 0.45, (0, 200, 210)), (0.6, 0.1, 0.4, (30, 60, 160))]),
    ("forest", (6, 14, 10), [(0.1, 0.1, 0.5, (40, 160, 90)), (0.9, 0.9, 0.55, (120, 180, 60)), (0.55, 0.45, 0.3, (20, 110, 100))]),
    ("graphite", (14, 14, 16), [(0.2, 0.3, 0.6, (70, 70, 85)), (0.85, 0.85, 0.5, (55, 60, 75))]),
]

ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
for name, bg, blobs in THEMES:
    img = np.zeros((H, W, 3), np.float32) + bg
    for bx, by, r, col in blobs:
        d = np.hypot(xs - bx * W, ys - by * H) / (r * W)
        a = np.exp(-(d ** 2) * 2.2) * 0.6  # плавное гауссово пятно без яркой точки в центре
        img += a[..., None] * (np.array(col, np.float32) - img) * 0.9
    # Затемнение снизу, чтобы подписи и ряды приложений читались.
    img *= (1 - 0.35 * (ys / H) ** 1.5)[..., None]
    img += np.random.default_rng(1).normal(0, 1.2, img.shape)  # лёгкий шум против полос
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))
    out.save(OUT / f"{name}.jpg", quality=92)
    print(OUT / f"{name}.jpg")
