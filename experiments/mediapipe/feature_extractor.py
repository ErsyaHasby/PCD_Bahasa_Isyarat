"""
Feature Extractor — Python version (eksperimen/training).
HARUS identik dengan HandFeatureExtractor di Flutter.

Normalisasi per PRD 8.2:
  - Relatif ke wrist (landmark 0) per tangan
  - Skala: Euclidean distance wrist → middle finger MCP (landmark 9)

Output format per PRD 8.3:
  - 2 tangan × 21 titik = 42 titik
  - Flatten 126 (x,y,z) atau 84 (x,y) fallback
  - hand_count flag (0, 1, 2)
"""

import math
import numpy as np

LANDMARK_COUNT = 21
FINGERTIP_INDICES = [4, 8, 12, 16, 20]
FINGER_JOINTS = [
    [5, 6, 7],    # index MCP-PIP-DIP
    [9, 10, 11],  # middle MCP-PIP-DIP
    [13, 14, 15], # ring MCP-PIP-DIP
    [17, 18, 19], # pinky MCP-PIP-DIP
]
MCP_INDICES = [5, 9, 13, 17]


def dist(a, b):
    """Euclidean distance — HARUS sqrt, bukan squared."""
    return math.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2 + (a[2]-b[2])**2)


def angle(a, b, c):
    """Sudut antara vektor ba dan bc di titik b."""
    v1 = (a[0]-b[0], a[1]-b[1], a[2]-b[2])
    v2 = (c[0]-b[0], c[1]-b[1], c[2]-b[2])
    dot = v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]
    m1 = math.sqrt(v1[0]**2 + v1[1]**2 + v1[2]**2)
    m2 = math.sqrt(v2[0]**2 + v2[1]**2 + v2[2]**2)
    if m1 < 1e-6 or m2 < 1e-6:
        return 0.0
    return math.acos(max(-1.0, min(1.0, dot / (m1 * m2))))


def normalize_hand(raw):
    """
    Normalisasi satu tangan (21 landmarks).
    Input: list of (x, y, z) — koordinat absolut dari MediaPipe.
    Output: list of (x, y, z) — wrist-relative, skala MCP.
    """
    if len(raw) < LANDMARK_COUNT:
        return [(0.0, 0.0, 0.0)] * LANDMARK_COUNT

    wrist = raw[0]
    mcp = raw[9]

    scale = math.sqrt(
        (mcp[0] - wrist[0])**2 +
        (mcp[1] - wrist[1])**2 +
        (mcp[2] - wrist[2])**2
    )

    if scale < 1e-6:
        return [(0.0, 0.0, 0.0)] * LANDMARK_COUNT

    return [
        ((lm[0] - wrist[0]) / scale,
         (lm[1] - wrist[1]) / scale,
         (lm[2] - wrist[2]) / scale)
        for lm in raw
    ]


def normalize(hands):
    """
    Normalisasi maksimal 2 tangan.
    hands: list of list of (x,y,z) — raw landmarks per tangan.
    Returns: list of 2 normalized hands (tangan kedua nol jika < 2).
    """
    result = []
    for h in range(2):
        if h < len(hands) and hands[h] is not None:
            result.append(normalize_hand(hands[h]))
        else:
            result.append([(0.0, 0.0, 0.0)] * LANDMARK_COUNT)
    return result


def flatten(hands, use_z=True):
    """
    Flatten 2 tangan ke vektor 1D.
    2 × 21 × (2 atau 3) = 84 atau 126.
    """
    features = []
    for h in range(2):
        for lm in hands[h]:
            features.append(lm[0])
            features.append(lm[1])
            if use_z:
                features.append(lm[2])
    return np.array(features, dtype=np.float32)


def finger_distances(lm):
    """Jarak wrist ke tiap ujung jari + pinch + palm width."""
    distances = [dist(lm[0], lm[i]) for i in FINGERTIP_INDICES]
    pinch = dist(lm[4], lm[8])
    palm_width = dist(lm[5], lm[17])
    return distances + [pinch, palm_width]


def finger_angles(lm):
    """Curl angle per jari + spread angle antar jari."""
    angles = []
    for joint in FINGER_JOINTS:
        angles.append(angle(lm[joint[0]], lm[joint[1]], lm[joint[2]]))
    for i in range(len(MCP_INDICES) - 1):
        angles.append(angle(lm[0], lm[MCP_INDICES[i]], lm[MCP_INDICES[i+1]]))
    return angles


def finger_ratios(lm):
    """Rasio panjang jari relatif ke jari tengah."""
    lengths = [
        dist(lm[5], lm[8]),   # index
        dist(lm[9], lm[12]),  # middle
        dist(lm[13], lm[16]), # ring
        dist(lm[17], lm[20]), # pinky
    ]
    mid = lengths[1]
    if mid < 1e-6:
        return [0.0, 0.0, 0.0, 0.0]
    return [
        lengths[0] / mid,
        lengths[2] / mid,
        lengths[3] / mid,
        dist(lm[1], lm[5]) / mid,
    ]


def extract_geometric(hands):
    """Ekstrak geometric features untuk 2 tangan."""
    features = []
    for h in range(2):
        lm = hands[h]
        features.extend(finger_distances(lm))
        features.extend(finger_angles(lm))
        features.extend(finger_ratios(lm))
    return np.array(features, dtype=np.float32)


def hand_count(hands):
    """Deteksi jumlah tangan (hand_count flag)."""
    def is_nonzero(lm):
        return abs(lm[0]) > 1e-6 or abs(lm[1]) > 1e-6 or abs(lm[2]) > 1e-6

    count = 0
    if any(is_nonzero(lm) for lm in hands[0]):
        count += 1
    if len(hands) > 1 and any(is_nonzero(lm) for lm in hands[1]):
        count += 1
    return count


def extract_all(hands, use_z=True):
    """
    Ekstrak semua fitur dari raw MediaPipe landmarks.
    Output siap untuk training/inference.

    Args:
        hands: list of list of (x,y,z), maksimal 2 tangan.
        use_z: True → 126, False → 84.

    Returns:
        dict dengan keys:
          - landmark_vector: np.array (126 atau 84)
          - geometric_features: np.array (geometric)
          - hand_count: int (0, 1, 2)
          - combined: np.array (landmark_vector + geometric_features)
    """
    norm_hands = normalize(hands)
    lv = flatten(norm_hands, use_z=use_z)
    gf = extract_geometric(norm_hands)
    hc = hand_count(norm_hands)

    return {
        'landmark_vector': lv,
        'geometric_features': gf,
        'hand_count': hc,
        'combined': np.concatenate([lv, gf]),
    }
