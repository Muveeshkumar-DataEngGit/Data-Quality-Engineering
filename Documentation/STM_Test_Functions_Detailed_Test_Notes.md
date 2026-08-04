# STM Test Functions - Detailed Test Notes Above Code

Each test class is analyzed as one validation unit. The note explains what behavior is protected, why it matters, scenarios covered, and the production risk if the test fails.

## `TestSplitAKA`

**Source lines:** 7-39

**Purpose:** Validates alternate-title splitting behavior.

**Why this test block matters:** If AKA splitting fails, STM searches fewer title variants and candidate recall drops.

**Scenarios covered:**
- Standard AKA syntax
- Slash-separated titles
- Parenthetical AKA values
- Mixed separators
- Blank string handling
- None handling

**Risk if this test fails:** Incorrect or missed matches where the correct ATOM record is stored under an alternate title.

**Test functions inside this class:**
- `test_split_aka()` lines 38-39

```python
class TestSplitAKA:
    
    @pytest.mark.parametrize("title,output",[
    # ✅ Basic AKA patterns
    ("Spring AKA Summer", ["Spring", "Summer"]),
    ("Spring / Summer", ["Spring", "Summer"]),
    ("Spring AKA Summer / Winter", ["Spring", "Summer", "Winter"]),

    # ✅ Parentheses AKA
    ("Spring (AKA. Daugues, Mufgh, bgdus)", ["Spring", "Daugues", "Mufgh", "bgdus"]),
    ("Spring (AKA Daugues, Mufgh)", ["Spring", "Daugues", "Mufgh"]),
    ("Spring( AKA. daufuu)", ["Spring", "daufuu"]),
    ("Spring(AKA daufuu)", ["Spring", "daufuu"]),

    # ✅ Case variations
    ("Spring (aka daufuu, test)", ["Spring", "daufuu", "test"]),

    # ✅ Spacing issues
    (" Spring   (   AKA.   A, B   ) ", ["Spring", "A", "B"]),
    ("Spring(AKA. A,B,C)", ["Spring", "A", "B", "C"]),

    # ✅ Mixed separators (fallback cases)
    ("Spring AKA A / B / C", ["Spring", "A", "B", "C"]),
    ("Spring / A AKA B", ["Spring", "A", "B"]),

    # ✅ Single / edge
    ("Spring", ["Spring"]),
    ("", []),
    (None, [None])
])

    def test_split_aka(self,title,output):
        assert smart_title_matching_functions.split_aka(title)==output, f"Failed for: {title}"
```

---

## `TestNormalizeTitles`

**Source lines:** 41-92

**Purpose:** Validates title cleaning and normalization rules.

**Why this test block matters:** Normalization directly affects SQL candidate retrieval, semantic scoring, and final decision quality.

**Scenarios covered:**
- Case normalization
- Accent removal
- Punctuation cleanup
- Trailing year handling
- Version phrase removal
- Whitespace cleanup
- Null handling

**Risk if this test fails:** False mismatches caused by casing, accents, punctuation, or version labels.

**Test functions inside this class:**
- `test_normalize_title()` lines 91-92

```python
class TestNormalizeTitles:
   
    @pytest.mark.parametrize("title, output", [

        # ✅ Basic normalization
        ("Spring", "spring"),
        ("SPRING", "spring"),
        ("Spring Movie", "spring movie"),

        # ✅ Unicode + accent removal
        ("Amélie", "amelie"),
        ("Café Society", "cafe society"),
        ("Pokémon", "pokemon"),

        # ✅ Punctuation removal
        ("Spider-Man: No Way Home!", "spider-man no way home"),
        ("Hello, World!!!", "hello world"),
        ("It's a Test", "it's a test"),

        # ✅ Year removal
        ("Spring 2023", "spring"),
        ("Movie 1999", "movie"),
        ("Test 2020", "test"),

        # ✅ Year should NOT be removed if not at end
        ("2023 Spring", "2023 spring"),
        ("Movie 2020 Edition", "movie 2020 edition"),

        # ✅ Version cleanup
        ("Spring SUBTITLED VERSION", "spring"),
        ("Spring EDITED VERSION", "spring"),
        ("Spring SUBTITLED", "spring"),
        ("Spring subtitles", "spring"),

        # ✅ Combined messy cases (IMPORTANT for you)
        ("Amélie (2001) SUBTITLED VERSION", "amelie 2001"),
        ("Spider-Man: No Way Home 2021", "spider-man no way home"),
        ("Café Society (2016) EDITED VERSION", "cafe society 2016"),

        # ✅ Extra spaces
        ("   Spring   Movie   ", "spring movie"),
        ("Spring     2022   ", "spring"),

        # ✅ Special characters
        ("Movie @#$%^&*", "movie"),

        # ✅ Edge cases
        ("", ""),
        (None, ""),
    ])
    def test_normalize_title(self,title, output):
        assert smart_title_matching_functions.normalize_title(title) == output, f"Failed for: {title}"
```

---

## `TestGenricMerger`

**Source lines:** 95-157

**Purpose:** Validates generic episode enrichment.

**Why this test block matters:** Generic episode titles require parent-series and season/episode context to avoid ambiguous matches.

**Scenarios covered:**
- Normal values
- String and float numbers
- Missing season or episode
- Empty series title
- Non-numeric fallback
- Whitespace cleanup

**Risk if this test fails:** Episodes like `Episode 1` may match the wrong series or fail to match properly.

**Test functions inside this class:**
- `test_genric_merger()` lines 154-157

```python
class TestGenricMerger:

    @pytest.mark.parametrize("title, series_title, season_number, episode_number, expected", [

        # ✅ Normal valid inputs
        ("Episode Title", "Series Name", 1, 2, 
        "Episode Title (AKA. Series Name S1 Episode 2)"),

        ("Ep", "Show", "2", "3",
        "Ep (AKA. Show S2 Episode 3)"),

        # ✅ Float normalization
        ("Ep", "Show", 1.0, 2.0,
        "Ep (AKA. Show S1 Episode 2)"),

        ("Ep", "Show", "1.0", "2.0",
        "Ep (AKA. Show S1 Episode 2)"),

        # ✅ With empty series title
        ("Episode Title", "", 1, 2,
        "Episode Title (AKA. S1 Episode 2)"),

        ("Episode Title", None, 1, 2,
        "Episode Title (AKA. S1 Episode 2)"),

        # ✅ Missing season or episode → should return original title
        ("Episode Title", "Series", None, 2, "Episode Title"),
        ("Episode Title", "Series", 1, None, "Episode Title"),
        ("Episode Title", "Series", "", 2, "Episode Title"),
        ("Episode Title", "Series", 1, "", "Episode Title"),

        # ✅ Episode number normalization
        ("Ep", "Show", 1, "02",
        "Ep (AKA. Show S1 Episode 2)"),

        # ✅ Season normalization (non-integer float should remain)
        ("Ep", "Show", 1.5, 2,
        "Ep (AKA. Show S1.5 Episode 2)"),

        # ✅ Episode normalization (non-integer float should remain)
        ("Ep", "Show", 1, 2.7,
        "Ep (AKA. Show S1 Episode 2.7)"),

        # ✅ Non-numeric episode → fallback
        ("Ep", "Show", 1, "abc", "Ep"),

        # ✅ Non-numeric season → still works (your current logic allows it)
        ("Ep", "Show", "S1", 2,
        "Ep (AKA. Show SS1 Episode 2)"),

        # ✅ Extra spaces
        ("Ep", "  Show  ", " 1 ", " 2 ",
        "Ep (AKA. Show S1 Episode 2)"),

        # ✅ Both numeric but string formatted messy
        ("Ep", "Show", "01", "002",
        "Ep (AKA. Show S1 Episode 2)"),

    ])
    def test_genric_merger(self,title, series_title, season_number, episode_number, expected):
        assert smart_title_matching_functions.genric_merger(
            title, series_title, season_number, episode_number
        ) == expected, f"Failed for: {title}, {series_title}, {season_number}, {episode_number}"
```

---

## `TestTopnperID`

**Source lines:** 159-255

**Purpose:** Validates candidate ranking and high-score preservation.

**Why this test block matters:** STM must reduce review volume without discarding very high-confidence candidates.

**Scenarios covered:**
- All high scores retained
- Mixed high and low scores
- Fallback to top N
- Multiple input IDs
- Score exactly equal to threshold
- Groups smaller than N

**Risk if this test fails:** Top matches may be lost or excessive low-quality candidates may appear in output.

**Test functions inside this class:**
- `test_top_n_per_id()` lines 248-255

```python
class TestTopnperID:

    @pytest.mark.parametrize("data, expected", [

        # ✅ Case 1: High scores ≥ 90 → return ALL of them (ignore n)
        (
            pd.DataFrame({
                "id": ["A", "A", "A", "A"],
                "score": [95, 92, 91,99]
            }),
            pd.DataFrame({
                "id": ["A","A", "A", "A"],
                "score": [99, 95, 92, 91]
            })
        ),

        # ✅ Case 2: Mix ≥90 and <90 → only ≥90 returned
        (
            pd.DataFrame({
                "id": ["A", "A", "A"],
                "score": [95, 92, 85]
            }),
            pd.DataFrame({
                "id": ["A", "A"],
                "score": [95, 92]
            })
        ),

        # ✅ Case 3: No ≥90 → return top N
        (
            pd.DataFrame({
                "id": ["A", "A", "A"],
                "score": [88, 87, 80]
            }),
            pd.DataFrame({
                "id": ["A", "A","A"],
                "score": [88, 87, 80]
            })
        ),

        # ✅ Case 4: Multiple IDs mix
        (
            pd.DataFrame({
                "id": ["A", "A", "B", "B", "B"],
                "score": [95, 85, 88, 87, 91]
            }),
            pd.DataFrame({
                "id": ["A", "B"],
                "score": [95, 91]
            })
        ),

        # ✅ Case 5: Exactly equal to 90 included
        (
            pd.DataFrame({
                "id": ["A", "A"],
                "score": [90, 89]
            }),
            pd.DataFrame({
                "id": ["A"],
                "score": [90]
            })
        ),

        # ✅ Case 6: n larger than group (no ≥90)
        (
            pd.DataFrame({
                "id": ["A", "A"],
                "score": [85, 80]
            }),
            pd.DataFrame({
                "id": ["A", "A"],
                "score": [85, 80]
            })
        ),

        # ✅ Case 7: Multiple groups, mixed behavior
        (
            pd.DataFrame({
                "id": ["A", "A", "B", "B"],
                "score": [95, 80, 88, 85]
            }),
            pd.DataFrame({
                "id": ["A", "B", "B"],
                "score": [95, 88, 85]
            })
        ),

    ])
    def test_top_n_per_id(self,data, expected):
        result = smart_title_matching_functions.top_n_per_id(data, "id", "score", n=3)

        # Reset index for clean comparison
        result = result.reset_index(drop=True)
        expected = expected.reset_index(drop=True)

        pd.testing.assert_frame_equal(result, expected)
```

---

## `TestgetSnowflakeConnection`

**Source lines:** 257-266

**Purpose:** Validates Snowflake connection failure behavior.

**Why this test block matters:** Connection failures should surface clearly so the script does not continue with invalid or missing data.

**Scenarios covered:**
- Mocked Snowflake connector raises exception
- Exception is propagated and message is preserved

**Risk if this test fails:** Silent data-access failures or misleading empty outputs.

**Test functions inside this class:**
- `test_connection_failure()` lines 260-266

```python
class TestgetSnowflakeConnection:

    @patch("snowflake.connector.connect")
    def test_connection_failure(self, mock_connect):
        mock_connect.side_effect = Exception("Connection failed")

        with pytest.raises(Exception) as exc:
            smart_title_matching_functions.get_connection()

        assert "Connection failed" in str(exc.value)
```

---

