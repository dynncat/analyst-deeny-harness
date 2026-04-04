# 시각화 스타일 가이드

## 기본 설정

```python
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import seaborn as sns

# 한글 폰트
plt.rcParams['font.family'] = 'AppleGothic'  # macOS
plt.rcParams['axes.unicode_minus'] = False

# 기본 스타일
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)
plt.rcParams['font.size'] = 11
```

## 제목 작성 규칙

제목에는 분석 조건을 구체적으로 드러낼 것:

```
❌ "DAU 추이"
✅ "출석체크 개편 (3/15) 전후 30일간 DAU 변화 추이"

❌ "퍼널 전환율"
✅ "온보딩 퍼널 단계별 전환율 (2024.03.01~03.31, 신규 유저)"

❌ "코호트 리텐션"
✅ "2024년 3월 가입 코호트 주차별 리텐션율 (OS별 비교)"
```

## 기준선 표시

### 이벤트 날짜 수직선
```python
ax.axvline(x=event_date, color='red', linestyle='--', alpha=0.7,
           label='기능 출시일 (3/15)')
```

### 평균 수평선
```python
ax.axhline(y=avg_value, color='gray', linestyle=':', alpha=0.5,
           label=f'기간 평균 ({avg_value:,.0f})')
```

### 범례는 항상 표시
```python
ax.legend(loc='best', fontsize=9)
```

## 그래프 유형별 가이드

| 유형 | 용도 | 필수 요소 |
|------|------|----------|
| 시계열 추이 | 날짜별 변화 | 날짜 기준선 + 평균선 + 이벤트 마커 |
| 퍼널 | 단계별 전환 | 가로 막대 + 전환율 텍스트 annotation |
| 비교 (A/B, 세그먼트) | 그룹 간 차이 | 그룹별 색상 + 수치 레이블 |
| 분포 | 값 분포 확인 | 히스토그램/박스플롯 + 중앙값/평균 마커 |
| 코호트 히트맵 | 리텐션 등 | 히트맵 + 수치 annotation |

## 이미지 저장

```python
plt.tight_layout()
plt.savefig('output/[분석주제]_[차트설명].png', dpi=150, bbox_inches='tight')
plt.show()
```
