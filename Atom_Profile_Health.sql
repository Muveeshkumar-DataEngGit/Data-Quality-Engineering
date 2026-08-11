-- Weighted, type-aware profile health framework scoring completeness, hierarchy integrity and format hygiene for ATOM titles.
-- Co-authored with CoCo

// Attributes_completeness_matric by IP_TYPE:

WITH ATTRIBUTE_COMPLENESS AS(
SELECT
CASE 
    WHEN UPPER(IP_TYPE) 
    NOT IN (
    'SERIES',
    'MINI SERIES',
    'SEASON',
    'PODCAST',
    'MADE FOR VIDEO',
    'EPISODE',
    'SPECIAL',
    'FEATURE',
    'SHORT',
    'TV MOVIE',
    'PILOT',
    'SEGMENT') 
    OR IP_TYPE IS NULL
    THEN 'UNKNOWN'
    ELSE UPPER(IP_TYPE)
END AS IP_TYPE_CATEGORY,
LIBRARY_TITLE_FULL,
LIBRARY_TITLE_SHORT,
IP_TYPE,
ORIGINAL_RELEASE_YEAR,
PI_UUID,
MPM_NUMBER,
NUMBER_OF_EPISODES,
META_ID,
PROPERTY_ID,
TURNER_TITLEID,
GENRE,
END_YEAR,
START_YEAR,
ORIGINALLY_AIRED_AS,
MPM_FAMILY_NUMBER,
MPM_PRODUCT_NUMBER
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE
)
SELECT 
IP_TYPE_CATEGORY,

CONCAT(ROUND(COUNT(LIBRARY_TITLE_FULL) / COUNT(*) * 100,1),'%') AS LIBRARY_TITLE_FULL,
CONCAT(ROUND(COUNT(LIBRARY_TITLE_SHORT) / COUNT(*) * 100,1),'%') AS LIBRARY_TITLE_SHORT,
CONCAT(ROUND(COUNT(IP_TYPE) / COUNT(*) * 100,1),'%') AS IP_TYPE,
CONCAT(ROUND(COUNT(ORIGINAL_RELEASE_YEAR) / COUNT(*) * 100,1),'%') AS ORIGINAL_RELEASE_YEAR,
CONCAT(ROUND(COUNT(PI_UUID) / COUNT(*) * 100,1),'%') AS PI_UUID,
CONCAT(ROUND(COUNT(MPM_NUMBER) / COUNT(*) * 100,1),'%') AS MPM_NUMBER,
CONCAT(ROUND(COUNT(NUMBER_OF_EPISODES) / COUNT(*) * 100,1),'%') AS NUMBER_OF_EPISODES,
CONCAT(ROUND(COUNT(META_ID) / COUNT(*) * 100,1),'%') AS META_ID,
CONCAT(ROUND(COUNT(PROPERTY_ID) / COUNT(*) * 100,1),'%') AS PROPERTY_ID,
CONCAT(ROUND(COUNT(TURNER_TITLEID) / COUNT(*) * 100,1),'%') AS TURNER_TITLEID,
CONCAT(ROUND(COUNT(GENRE) / COUNT(*) * 100,1),'%') AS GENRE,
CONCAT(ROUND(COUNT(END_YEAR) / COUNT(*) * 100,1),'%') AS END_YEAR,
CONCAT(ROUND(COUNT(START_YEAR) / COUNT(*) * 100,1),'%') AS START_YEAR,
CONCAT(ROUND(COUNT(ORIGINALLY_AIRED_AS) / COUNT(*) * 100,1),'%') AS ORIGINALLY_AIRED_AS,
CONCAT(ROUND(COUNT(MPM_FAMILY_NUMBER) / COUNT(*) * 100,1),'%') AS MPM_FAMILY_NUMBER,
CONCAT(ROUND(COUNT(MPM_PRODUCT_NUMBER) / COUNT(*) * 100,1),'%') AS MPM_PRODUCT_NUMBER

FROM ATTRIBUTE_COMPLENESS
GROUP BY IP_TYPE_CATEGORY
ORDER BY IP_TYPE_CATEGORY;




// Profile Completion Categorization by Percentage:

// 1). Merging the Applicability_Matrix with the ATOM profiles:
WITH PROFILE_COM AS(
    SELECT 
        T.NODE_IDENTIFIER,
        T.IP_TYPE,
        Profile_Completeness AS PROFILE_COMPLETENESS 
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    INNER JOIN 
    (WITH Applicability_Matrix AS(
    // 1.1). Applicability_Matrix Created as a Temp table for scoring
    SELECT *
    FROM (
        VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
    ) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
    ),
    
    // 1.2). ATTRIBUTES_Completeness - Gathered only the important columns for tracking
    ATTRIBUTES_Completeness AS(
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_FULL' AS Attribute_name,
            LIBRARY_TITLE_FULL AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_SHORT' AS Attribute_name,
            LIBRARY_TITLE_SHORT AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'IP_TYPE' AS Attribute_name,
            IP_TYPE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
            ORIGINAL_RELEASE_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PI_UUID' AS Attribute_name,
            PI_UUID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_NUMBER' AS Attribute_name,
            MPM_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'NUMBER_OF_EPISODES' AS Attribute_name,
            NUMBER_OF_EPISODES AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'META_ID' AS Attribute_name,
            META_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PROPERTY_ID' AS Attribute_name,
            PROPERTY_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'TURNER_TITLEID' AS Attribute_name,
            TURNER_TITLEID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'GENRE' AS Attribute_name,
            GENRE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'END_YEAR' AS Attribute_name,
            END_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'START_YEAR' AS Attribute_name,
            START_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINALLY_AIRED_AS' AS Attribute_name,
            ORIGINALLY_AIRED_AS AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_FAMILY_NUMBER' AS Attribute_name,
            MPM_FAMILY_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_PRODUCT_NUMBER' AS Attribute_name,
            MPM_PRODUCT_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    ),

    // 1.3). Creating IS_PRESENT column to check the values are there or not
    ATTRIBUTES_Completeness1 AS(
    SELECT *,
        CASE 
            WHEN ATTRIBUTE_VALUE IS NOT NULL
            THEN 1
            ELSE 0
        END AS IS_PRESENT
    FROM ATTRIBUTES_Completeness A
    ORDER BY PROFILE_ID
    ),
    
    // 1.4). Creating the IP_TYPE categories to have a standard format, other than know ip's all the others consider as  "UNKNOWN"
    IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
    ),

    // 1.5). Merging the IP_TYPE table to the ATTRIBUTES_Completeness table
    ATTRIBUTES_Completeness2 AS(
    SELECT 
        A.PROFILE_ID,
        A.ATTRIBUTE_NAME,
        IP.ATTRIBUTE_VALUE AS IP_TYPE,
        A.ATTRIBUTE_VALUE,
        A.IS_PRESENT 
    FROM ATTRIBUTES_Completeness1 A
    LEFT JOIN IP_TYPES IP
    ON A.PROFILE_ID=IP.PROFILE_ID
    ),

    // 1.6). Merging the ATTRIBUTES_Completeness table with Applicability_Matrix to check wheather a particular column is needs for that profile or not, according to the IP_TYPE and the weights are added;
    Attribute_weight as(
    SELECT 
        AC.PROFILE_ID,
        AC.ATTRIBUTE_NAME,
        AC.IP_TYPE,
        //AC.ATTRIBUTE_VALUE,
        AC.IS_PRESENT,
        CASE WHEN AM.CRITICALITY IS NULL
             THEN 0
             ELSE 1
        END AS IS_APPLIACABLE,
        AM.Applicability, 
        AM.Criticality, 
        AM.weight
    FROM ATTRIBUTES_Completeness2 AC
    LEFT JOIN Applicability_Matrix AM ON
    AC.IP_TYPE=UPPER(AM.Ip_type)
    AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
    ),

    // 1.7). Calculating the overall weights for individual profiles
    TOTAL_WEIGHT AS(
    SELECT 
        PROFILE_ID,IP_TYPE,
        SUM(
        CASE WHEN IS_APPLIACABLE=1 AND IS_PRESENT=1
             THEN weight
             ELSE 0
        END) AS T_WEIGHT
    FROM Attribute_weight
    GROUP BY PROFILE_ID,IP_TYPE
    )

    // 1.8). The total_weights are converted into percentage according to the IP_TYPES
    SELECT
        PROFILE_ID,
        T_WEIGHT,
        ROUND(CASE 
            WHEN UPPER(IP_TYPE)='SERIES'
            THEN T_WEIGHT/66*100
            WHEN UPPER(IP_TYPE)='SEASON'
            THEN T_WEIGHT/83*100
            WHEN UPPER(IP_TYPE)='EPISODE'
            THEN T_WEIGHT/76*100
            ELSE T_WEIGHT/64*100
        END,0) AS Profile_Completeness
    FROM TOTAL_WEIGHT) AS weight
    ON T.NODE_IDENTIFIER=weight.PROFILE_ID
),

// Hierarchy Integrity Table (LINEAGE CHECK)
// 2). Taking only required columns from the HIERARCHY Table
Heirachy_Integrity as
(

// 2.1). Taking only required columns from the HIERARCHY Table
WITH ATOM_DATA AS (
    SELECT 
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        E.MPM_NUMBER,
        E.SEASON_MPM_NUMBER,
        E.SERIES_MPM_NUMBER
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.EPISODIC_TITLE_HIERARCHY_VW E
),

-- 2.2) Merging the Atom table with D_TITLE to fill missing SEASON_MPM_NUMBER and SERIES_MPM_NUMBER
HIERARCHY_INFO1 AS (
    SELECT
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        COALESCE(E.MPM_NUMBER,T.MPM_NUMBER) AS EPISODE_MPM_NUMBER,
        COALESCE(E.SEASON_MPM_NUMBER, T.MPM_PRODUCT_NUMBER) AS SEASON_MPM_NUMBER,
        COALESCE(E.SERIES_MPM_NUMBER, T.MPM_FAMILY_NUMBER) AS SERIES_MPM_NUMBER,
        T.PROPERTY_ID,
        T.PI_UUID
    FROM ATOM_DATA E
    LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
        ON E.NODE_IDENTIFIER = T.NODE_IDENTIFIER
),

-- 2.3) Creating lookup table for SERIES_IDENTIFIER
SERIES_LOOKUP AS (
SELECT
    SERIES_MPM_NUMBER,
    MAX(SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
FROM HIERARCHY_INFO1
GROUP BY SERIES_MPM_NUMBER
),

FILLING_IDENTIFIERS AS(
SELECT
    SL.SERIES_MPM_NUMBER,
    T.NODE_IDENTIFIER AS SERIES_IDENTIFIER
FROM SERIES_LOOKUP SL
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    ON SL.SERIES_MPM_NUMBER = T.MPM_NUMBER
WHERE T.NODE_IDENTIFIER IS NOT NULL
),

-- 2.4) Filling missing SERIES_IDENTIFIER and SEASON_IDENTIFIER
HIERARCHY_INFO_F AS(
SELECT
    COALESCE(H.SERIES_IDENTIFIER, SL.SERIES_IDENTIFIER, SSL.SERIES_IDENTIFIER) AS SERIES_IDENTIFIER,
    SSL.SEASON_IDENTIFIER,
    H.NODE_IDENTIFIER,
    H.IP_TYPE,
    H.EPISODE_MPM_NUMBER,
    H.SEASON_MPM_NUMBER,
    COALESCE(H.SERIES_MPM_NUMBER, SSL.SERIES_MPM_NUMBER) AS SERIES_MPM_NUMBER,
    H.PROPERTY_ID,
    H.PI_UUID
FROM HIERARCHY_INFO1 H

LEFT JOIN FILLING_IDENTIFIERS SL
    ON H.SERIES_MPM_NUMBER = SL.SERIES_MPM_NUMBER

LEFT JOIN (
    SELECT
        SEASON_IDENTIFIER,
        SEASON_MPM_NUMBER,
        SERIES_IDENTIFIER,
        SERIES_MPM_NUMBER
    FROM (
        SELECT
            H2.SEASON_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SEASON_IDENTIFIER,
            T.MPM_FAMILY_NUMBER AS SERIES_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SERIES_IDENTIFIER,
            ROW_NUMBER() OVER (
                PARTITION BY H2.SEASON_MPM_NUMBER
                ORDER BY T.NODE_IDENTIFIER
            ) AS RN
        FROM HIERARCHY_INFO1 H2
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H2.SEASON_MPM_NUMBER = T.MPM_NUMBER
    )
    WHERE RN = 1
) SSL
    ON H.SEASON_MPM_NUMBER = SSL.SEASON_MPM_NUMBER)
SELECT 
CASE 
    WHEN HF.NODE_IDENTIFIER=HF.SERIES_IDENTIFIER THEN NULL 
    ELSE HF.SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
HF.SEASON_IDENTIFIER,
HF.NODE_IDENTIFIER,
HF.IP_TYPE,
T.MPM_FAMILY_NUMBER,
T.MPM_PRODUCT_NUMBER,
T.MPM_NUMBER
FROM HIERARCHY_INFO_F HF
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
ON HF.NODE_IDENTIFIER=T.NODE_IDENTIFIER),

// 2.5). Using the HEIRARCHY table creating the VALIDATION CONDITIONS
HEIRARCHY_STATE AS (
SELECT *,
    CASE
        WHEN NODE_IDENTIFIER IN (
            SELECT SERIES_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        WHEN SERIES_IDENTIFIER IN (
            SELECT NODE_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        ELSE 'NOT VALID'
    END AS HIERARCHY_STATUS,
    
// 2.6). Creating Booleans for ORPHAN_STATUS column to know the profile have parent or not
CASE
    WHEN NODE_IDENTIFIER IN 
    (SELECT H.SERIES_IDENTIFIER
     FROM Heirachy_Integrity H)
     THEN 'NO'
    WHEN MPM_FAMILY_NUMBER IS NOT NULL OR MPM_PRODUCT_NUMBER IS NOT NULL
    THEN 'NO'
    WHEN (IP_TYPE IS NULL OR  MPM_NUMBER IS NULL)
    THEN 'YES'
    ELSE 'YES'
END AS ORPHAN_STATUS
FROM Heirachy_Integrity
),
// 2.7). Parent of how many programs:
Heirachy_Integrity AS(
SELECT
CASE 
    WHEN SERIES_IDENTIFIER=NODE_IDENTIFIER THEN NULL 
    ELSE SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
SEASON_IDENTIFIER,
NODE_IDENTIFIER,
IP_TYPE,
MPM_FAMILY_NUMBER,
MPM_PRODUCT_NUMBER,
MPM_NUMBER
FROM Heirachy_Integrity
),
PARENT_LINK AS (
SELECT 
    NODE_IDENTIFIER,
    CASE 
        WHEN SUM(PARENT_COUNT) = 0 THEN 0
        ELSE SUM(PARENT_COUNT) -1
    END AS PARENT_OF
FROM (

    -- Series parent
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(B.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

    UNION ALL

    -- Season parent (avoid duplicate when series = season)
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(A.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SEASON_IDENTIFIER
        AND B.SEASON_IDENTIFIER <> B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

) T
GROUP BY NODE_IDENTIFIER
),
// 2.7). If any of the series related IP_TYPES created alone like not even in HEIRARCHY then that should be considered as ORPHAN and not valid HEIRARCHY status.
STATUS AS(
SELECT 
    PC.NODE_IDENTIFIER,
    PC.IP_TYPE,
    PC.PROFILE_COMPLETENESS,
    COALESCE(HS.HIERARCHY_STATUS, 'NOT_APPLICAPLE') 
    AS HIERARCHY_STATUS,
    COALESCE(HS.ORPHAN_STATUS,'NOT_APPLICAPLE') 
    AS ORPHAN_STATUS,
    PARENT_OF
FROM PROFILE_COM PC
LEFT JOIN HEIRARCHY_STATE HS
ON PC.NODE_IDENTIFIER=HS.NODE_IDENTIFIER
LEFT JOIN PARENT_LINK P
ON PC.NODE_IDENTIFIER=P.NODE_IDENTIFIER
),

// 3). Creating the Overall health column by utilizing three columns (HIERARCHY_STATUS, ORPHAN_STATUS, PROFILE_COMPLETENESS)
PROFILE_SUMMARY AS(
SELECT 
    NODE_IDENTIFIER AS PROFILE_ID,
    IP_TYPE,
    PROFILE_COMPLETENESS AS PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    CASE 
       WHEN HIERARCHY_STATUS='NOT VALID' THEN 'Critical'
       WHEN HIERARCHY_STATUS='NOT_APPLICAPLE' THEN 'Critical'
       WHEN ORPHAN_STATUS='YES' THEN 'Critical'
       WHEN PROFILE_COMPLETENESS<70 THEN 'Critical'
       WHEN PROFILE_COMPLETENESS BETWEEN 70 AND 90 THEN 'High Risk'
       ELSE 'Healthy'
    END AS OVERALL_HEALTH
FROM STATUS
),

// 3.1). Taking this ATTRIBUTES_Completeness table again to consider only IMPORTANT_FEATURES for creating COLUMN_DESCRIPTION.
IMPORTANT_FEATURES AS (
WITH Applicability_Matrix AS(
SELECT *
FROM (
    VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
),

// Attribute Completeness Matrix (FACT LAYER)
ATTRIBUTES_Completeness AS(
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_FULL' AS Attribute_name,
        LIBRARY_TITLE_FULL AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_SHORT' AS Attribute_name,
        LIBRARY_TITLE_SHORT AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'IP_TYPE' AS Attribute_name,
        IP_TYPE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
        ORIGINAL_RELEASE_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PI_UUID' AS Attribute_name,
        PI_UUID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_NUMBER' AS Attribute_name,
        MPM_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'NUMBER_OF_EPISODES' AS Attribute_name,
        NUMBER_OF_EPISODES AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'META_ID' AS Attribute_name,
        META_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PROPERTY_ID' AS Attribute_name,
        PROPERTY_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'TURNER_TITLEID' AS Attribute_name,
        TURNER_TITLEID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'GENRE' AS Attribute_name,
        GENRE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'END_YEAR' AS Attribute_name,
        END_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'START_YEAR' AS Attribute_name,
        START_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINALLY_AIRED_AS' AS Attribute_name,
        ORIGINALLY_AIRED_AS AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_FAMILY_NUMBER' AS Attribute_name,
        MPM_FAMILY_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_PRODUCT_NUMBER' AS Attribute_name,
        MPM_PRODUCT_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
),
ATTRIBUTES_Completeness1 AS(
SELECT *,
    CASE 
        WHEN ATTRIBUTE_VALUE IS NOT NULL
        THEN 1
        ELSE 0
    END AS IS_PRESENT
FROM ATTRIBUTES_Completeness A

ORDER BY PROFILE_ID
),
IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
),
ATTRIBUTES_Completeness2 AS(
SELECT 
    A.PROFILE_ID,
    A.ATTRIBUTE_NAME,
    IP.ATTRIBUTE_VALUE AS IP_TYPE,
    A.ATTRIBUTE_VALUE,
    A.IS_PRESENT 
FROM ATTRIBUTES_Completeness1 A
LEFT JOIN IP_TYPES IP
ON A.PROFILE_ID=IP.PROFILE_ID
),
Profile_columns as(
SELECT 
    AC.PROFILE_ID,
    AC.ATTRIBUTE_NAME,
    AC.IP_TYPE,
    AC.IS_PRESENT,
    CASE WHEN AM.CRITICALITY IS NULL
         THEN 0
         ELSE 1
    END AS IS_APPLIACABLE,
    AM.Applicability, 
    AM.Criticality, 
    AM.weight
FROM ATTRIBUTES_Completeness2 AC
LEFT JOIN Applicability_Matrix AM ON
AC.IP_TYPE=UPPER(AM.Ip_type)
AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
),

// 3.2). CONCATENATING the [column_name, it's_presence, how important it is for that profile]
GROUPED_DATA AS(
SELECT PROFILE_ID,
    CASE 
        WHEN IS_PRESENT=1 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS ,
    CASE 
        WHEN IS_PRESENT=0 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS_1 
FROM Profile_columns
)

// 3.3). Aggregating all columns together to create a GROUPED_COLUMN_DATA
SELECT 
    PROFILE_ID,
    LISTAGG(IMPORTANT_COLUMS, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS) AS PRESENT_COLUMNS,
    LISTAGG(IMPORTANT_COLUMS_1, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS_1) AS MISSING_COLUMNS
FROM GROUPED_DATA
GROUP BY PROFILE_ID
),

// 4). Finally the PROFILE_HELATH_SUMMARY Table
PROFILE_HELATH_SUMMARY AS(
SELECT 
    SPLIT_PART(P.PROFILE_ID,'/',2) AS ATOM_SEARCH,
    P.PROFILE_ID,
    IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    OVERALL_HEALTH,
    // 4.1). Giving enough space to each column for visiblity
    REGEXP_REPLACE(PRESENT_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS PRESENT_COLUMNS_DIS,
    REGEXP_REPLACE(MISSING_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS MISSING_COLUMNS_DIS
FROM PROFILE_SUMMARY P
LEFT JOIN IMPORTANT_FEATURES I 
ON P.PROFILE_ID=I.PROFILE_ID),
Profile_health_summary as (
SELECT
    //ATOM_SEARCH,
    PROFILE_ID,
    CASE 
        WHEN UPPER(IP_TYPE) 
        NOT IN (
        'SERIES',
        'MINI SERIES',
        'SEASON',
        'PODCAST',
        'MADE FOR VIDEO',
        'EPISODE',
        'SPECIAL',
        'FEATURE',
        'SHORT',
        'TV MOVIE',
        'PILOT',
        'SEGMENT') 
        OR IP_TYPE IS NULL
        THEN 'UNKNOWN'
        ELSE UPPER(IP_TYPE)
    END AS IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    //PARENT_OF,
    ARRAY_SIZE(SPLIT(PRESENT_COLUMNS_DIS,'|')) AS NUM_OF_COL_PRES,
    ARRAY_SIZE(SPLIT(MISSING_COLUMNS_DIS,'|')) AS NUM_OF_COL_MISS,
    OVERALL_HEALTH,
    //PRESENT_COLUMNS_DIS,
    //MISSING_COLUMNS_DIS
FROM PROFILE_HELATH_SUMMARY)
SELECT 
IP_TYPE,
SUM(
CASE WHEN PROFILE_COMPLETENESS<70 THEN 1 END) AS Less_than_70_percent,
SUM(
CASE WHEN PROFILE_COMPLETENESS BETWEEN 70 AND 90 THEN 1 END) AS Between_70_and_90_percent,
SUM(
CASE WHEN PROFILE_COMPLETENESS>90 THEN 1 END) AS Greater_than_90_percent
FROM Profile_health_summary
GROUP BY IP_TYPE
ORDER BY IP_TYPE;



// Number of profiles with VALID_HIERARCHY AND NOT_VALID_HIERARCHY:

// 1). Merging the Applicability_Matrix with the ATOM profiles:
WITH PROFILE_COM AS(
    SELECT 
        T.NODE_IDENTIFIER,
        T.IP_TYPE,
        Profile_Completeness AS PROFILE_COMPLETENESS 
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    INNER JOIN 
    (WITH Applicability_Matrix AS(
    // 1.1). Applicability_Matrix Created as a Temp table for scoring
    SELECT *
    FROM (
        VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
    ) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
    ),
    
    // 1.2). ATTRIBUTES_Completeness - Gathered only the important columns for tracking
    ATTRIBUTES_Completeness AS(
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_FULL' AS Attribute_name,
            LIBRARY_TITLE_FULL AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_SHORT' AS Attribute_name,
            LIBRARY_TITLE_SHORT AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'IP_TYPE' AS Attribute_name,
            IP_TYPE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
            ORIGINAL_RELEASE_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PI_UUID' AS Attribute_name,
            PI_UUID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_NUMBER' AS Attribute_name,
            MPM_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'NUMBER_OF_EPISODES' AS Attribute_name,
            NUMBER_OF_EPISODES AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'META_ID' AS Attribute_name,
            META_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PROPERTY_ID' AS Attribute_name,
            PROPERTY_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'TURNER_TITLEID' AS Attribute_name,
            TURNER_TITLEID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'GENRE' AS Attribute_name,
            GENRE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'END_YEAR' AS Attribute_name,
            END_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'START_YEAR' AS Attribute_name,
            START_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINALLY_AIRED_AS' AS Attribute_name,
            ORIGINALLY_AIRED_AS AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_FAMILY_NUMBER' AS Attribute_name,
            MPM_FAMILY_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_PRODUCT_NUMBER' AS Attribute_name,
            MPM_PRODUCT_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    ),

    // 1.3). Creating IS_PRESENT column to check the values are there or not
    ATTRIBUTES_Completeness1 AS(
    SELECT *,
        CASE 
            WHEN ATTRIBUTE_VALUE IS NOT NULL
            THEN 1
            ELSE 0
        END AS IS_PRESENT
    FROM ATTRIBUTES_Completeness A
    ORDER BY PROFILE_ID
    ),
    
    // 1.4). Creating the IP_TYPE categories to have a standard format, other than know ip's all the others consider as  "UNKNOWN"
    IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
    ),

    // 1.5). Merging the IP_TYPE table to the ATTRIBUTES_Completeness table
    ATTRIBUTES_Completeness2 AS(
    SELECT 
        A.PROFILE_ID,
        A.ATTRIBUTE_NAME,
        IP.ATTRIBUTE_VALUE AS IP_TYPE,
        A.ATTRIBUTE_VALUE,
        A.IS_PRESENT 
    FROM ATTRIBUTES_Completeness1 A
    LEFT JOIN IP_TYPES IP
    ON A.PROFILE_ID=IP.PROFILE_ID
    ),

    // 1.6). Merging the ATTRIBUTES_Completeness table with Applicability_Matrix to check wheather a particular column is needs for that profile or not, according to the IP_TYPE and the weights are added;
    Attribute_weight as(
    SELECT 
        AC.PROFILE_ID,
        AC.ATTRIBUTE_NAME,
        AC.IP_TYPE,
        //AC.ATTRIBUTE_VALUE,
        AC.IS_PRESENT,
        CASE WHEN AM.CRITICALITY IS NULL
             THEN 0
             ELSE 1
        END AS IS_APPLIACABLE,
        AM.Applicability, 
        AM.Criticality, 
        AM.weight
    FROM ATTRIBUTES_Completeness2 AC
    LEFT JOIN Applicability_Matrix AM ON
    AC.IP_TYPE=UPPER(AM.Ip_type)
    AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
    ),

    // 1.7). Calculating the overall weights for individual profiles
    TOTAL_WEIGHT AS(
    SELECT 
        PROFILE_ID,IP_TYPE,
        SUM(
        CASE WHEN IS_APPLIACABLE=1 AND IS_PRESENT=1
             THEN weight
             ELSE 0
        END) AS T_WEIGHT
    FROM Attribute_weight
    GROUP BY PROFILE_ID,IP_TYPE
    )

    // 1.8). The total_weights are converted into percentage according to the IP_TYPES
    SELECT
        PROFILE_ID,
        T_WEIGHT,
        ROUND(CASE 
            WHEN UPPER(IP_TYPE)='SERIES'
            THEN T_WEIGHT/66*100
            WHEN UPPER(IP_TYPE)='SEASON'
            THEN T_WEIGHT/83*100
            WHEN UPPER(IP_TYPE)='EPISODE'
            THEN T_WEIGHT/76*100
            ELSE T_WEIGHT/64*100
        END,0) AS Profile_Completeness
    FROM TOTAL_WEIGHT) AS weight
    ON T.NODE_IDENTIFIER=weight.PROFILE_ID
),

// Hierarchy Integrity Table (LINEAGE CHECK)
// 2). Taking only required columns from the HIERARCHY Table
Heirachy_Integrity as
(

// 2.1). Taking only required columns from the HIERARCHY Table
WITH ATOM_DATA AS (
    SELECT 
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        E.MPM_NUMBER,
        E.SEASON_MPM_NUMBER,
        E.SERIES_MPM_NUMBER
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.EPISODIC_TITLE_HIERARCHY_VW E
),

-- 2.2) Merging the Atom table with D_TITLE to fill missing SEASON_MPM_NUMBER and SERIES_MPM_NUMBER
HIERARCHY_INFO1 AS (
    SELECT
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        COALESCE(E.MPM_NUMBER,T.MPM_NUMBER) AS EPISODE_MPM_NUMBER,
        COALESCE(E.SEASON_MPM_NUMBER, T.MPM_PRODUCT_NUMBER) AS SEASON_MPM_NUMBER,
        COALESCE(E.SERIES_MPM_NUMBER, T.MPM_FAMILY_NUMBER) AS SERIES_MPM_NUMBER,
        T.PROPERTY_ID,
        T.PI_UUID
    FROM ATOM_DATA E
    LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
        ON E.NODE_IDENTIFIER = T.NODE_IDENTIFIER
),

-- 2.3) Creating lookup table for SERIES_IDENTIFIER
SERIES_LOOKUP AS (
SELECT
    SERIES_MPM_NUMBER,
    MAX(SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
FROM HIERARCHY_INFO1
GROUP BY SERIES_MPM_NUMBER
),

FILLING_IDENTIFIERS AS(
SELECT
    SL.SERIES_MPM_NUMBER,
    T.NODE_IDENTIFIER AS SERIES_IDENTIFIER
FROM SERIES_LOOKUP SL
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    ON SL.SERIES_MPM_NUMBER = T.MPM_NUMBER
WHERE T.NODE_IDENTIFIER IS NOT NULL
),

-- 2.4) Filling missing SERIES_IDENTIFIER and SEASON_IDENTIFIER
HIERARCHY_INFO_F AS(
SELECT
    COALESCE(H.SERIES_IDENTIFIER, SL.SERIES_IDENTIFIER, SSL.SERIES_IDENTIFIER) AS SERIES_IDENTIFIER,
    SSL.SEASON_IDENTIFIER,
    H.NODE_IDENTIFIER,
    H.IP_TYPE,
    H.EPISODE_MPM_NUMBER,
    H.SEASON_MPM_NUMBER,
    COALESCE(H.SERIES_MPM_NUMBER, SSL.SERIES_MPM_NUMBER) AS SERIES_MPM_NUMBER,
    H.PROPERTY_ID,
    H.PI_UUID
FROM HIERARCHY_INFO1 H

LEFT JOIN FILLING_IDENTIFIERS SL
    ON H.SERIES_MPM_NUMBER = SL.SERIES_MPM_NUMBER

LEFT JOIN (
    SELECT
        SEASON_IDENTIFIER,
        SEASON_MPM_NUMBER,
        SERIES_IDENTIFIER,
        SERIES_MPM_NUMBER
    FROM (
        SELECT
            H2.SEASON_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SEASON_IDENTIFIER,
            T.MPM_FAMILY_NUMBER AS SERIES_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SERIES_IDENTIFIER,
            ROW_NUMBER() OVER (
                PARTITION BY H2.SEASON_MPM_NUMBER
                ORDER BY T.NODE_IDENTIFIER
            ) AS RN
        FROM HIERARCHY_INFO1 H2
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H2.SEASON_MPM_NUMBER = T.MPM_NUMBER
    )
    WHERE RN = 1
) SSL
    ON H.SEASON_MPM_NUMBER = SSL.SEASON_MPM_NUMBER)
SELECT 
CASE 
    WHEN HF.NODE_IDENTIFIER=HF.SERIES_IDENTIFIER THEN NULL 
    ELSE HF.SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
HF.SEASON_IDENTIFIER,
HF.NODE_IDENTIFIER,
HF.IP_TYPE,
T.MPM_FAMILY_NUMBER,
T.MPM_PRODUCT_NUMBER,
T.MPM_NUMBER
FROM HIERARCHY_INFO_F HF
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
ON HF.NODE_IDENTIFIER=T.NODE_IDENTIFIER),

// 2.5). Using the HEIRARCHY table creating the VALIDATION CONDITIONS
HEIRARCHY_STATE AS (
SELECT *,
    CASE
        WHEN NODE_IDENTIFIER IN (
            SELECT SERIES_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        WHEN SERIES_IDENTIFIER IN (
            SELECT NODE_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        ELSE 'NOT VALID'
    END AS HIERARCHY_STATUS,
    
// 2.6). Creating Booleans for ORPHAN_STATUS column to know the profile have parent or not
CASE
    WHEN NODE_IDENTIFIER IN 
    (SELECT H.SERIES_IDENTIFIER
     FROM Heirachy_Integrity H)
     THEN 'NO'
    WHEN MPM_FAMILY_NUMBER IS NOT NULL OR MPM_PRODUCT_NUMBER IS NOT NULL
    THEN 'NO'
    WHEN (IP_TYPE IS NULL OR  MPM_NUMBER IS NULL)
    THEN 'YES'
    ELSE 'YES'
END AS ORPHAN_STATUS
FROM Heirachy_Integrity
),
// 2.7). Parent of how many programs:
Heirachy_Integrity AS(
SELECT
CASE 
    WHEN SERIES_IDENTIFIER=NODE_IDENTIFIER THEN NULL 
    ELSE SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
SEASON_IDENTIFIER,
NODE_IDENTIFIER,
IP_TYPE,
MPM_FAMILY_NUMBER,
MPM_PRODUCT_NUMBER,
MPM_NUMBER
FROM Heirachy_Integrity
),
PARENT_LINK AS (
SELECT 
    NODE_IDENTIFIER,
    CASE 
        WHEN SUM(PARENT_COUNT) = 0 THEN 0
        ELSE SUM(PARENT_COUNT) -1
    END AS PARENT_OF
FROM (

    -- Series parent
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(B.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

    UNION ALL

    -- Season parent (avoid duplicate when series = season)
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(A.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SEASON_IDENTIFIER
        AND B.SEASON_IDENTIFIER <> B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

) T
GROUP BY NODE_IDENTIFIER
),
// 2.7). If any of the series related IP_TYPES created alone like not even in HEIRARCHY then that should be considered as ORPHAN and not valid HEIRARCHY status.
STATUS AS(
SELECT 
    PC.NODE_IDENTIFIER,
    PC.IP_TYPE,
    PC.PROFILE_COMPLETENESS,
    COALESCE(HS.HIERARCHY_STATUS, 'NOT_APPLICAPLE') 
    AS HIERARCHY_STATUS,
    COALESCE(HS.ORPHAN_STATUS,'NOT_APPLICAPLE') 
    AS ORPHAN_STATUS,
    PARENT_OF
FROM PROFILE_COM PC
LEFT JOIN HEIRARCHY_STATE HS
ON PC.NODE_IDENTIFIER=HS.NODE_IDENTIFIER
LEFT JOIN PARENT_LINK P
ON PC.NODE_IDENTIFIER=P.NODE_IDENTIFIER
),

// 3). Creating the Overall health column by utilizing three columns (HIERARCHY_STATUS, ORPHAN_STATUS, PROFILE_COMPLETENESS)
PROFILE_SUMMARY AS(
SELECT 
    NODE_IDENTIFIER AS PROFILE_ID,
    IP_TYPE,
    PROFILE_COMPLETENESS AS PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    CASE 
       WHEN HIERARCHY_STATUS='NOT VALID' THEN 'Critical'
       WHEN HIERARCHY_STATUS='NOT_APPLICAPLE' THEN 'Critical'
       WHEN ORPHAN_STATUS='YES' THEN 'Critical'
       WHEN PROFILE_COMPLETENESS<70 THEN 'Critical'
       WHEN PROFILE_COMPLETENESS BETWEEN 70 AND 90 THEN 'High Risk'
       ELSE 'Healthy'
    END AS OVERALL_HEALTH
FROM STATUS
),

// 3.1). Taking this ATTRIBUTES_Completeness table again to consider only IMPORTANT_FEATURES for creating COLUMN_DESCRIPTION.
IMPORTANT_FEATURES AS (
WITH Applicability_Matrix AS(
SELECT *
FROM (
    VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
),

// Attribute Completeness Matrix (FACT LAYER)
ATTRIBUTES_Completeness AS(
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_FULL' AS Attribute_name,
        LIBRARY_TITLE_FULL AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_SHORT' AS Attribute_name,
        LIBRARY_TITLE_SHORT AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'IP_TYPE' AS Attribute_name,
        IP_TYPE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
        ORIGINAL_RELEASE_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PI_UUID' AS Attribute_name,
        PI_UUID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_NUMBER' AS Attribute_name,
        MPM_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'NUMBER_OF_EPISODES' AS Attribute_name,
        NUMBER_OF_EPISODES AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'META_ID' AS Attribute_name,
        META_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PROPERTY_ID' AS Attribute_name,
        PROPERTY_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'TURNER_TITLEID' AS Attribute_name,
        TURNER_TITLEID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'GENRE' AS Attribute_name,
        GENRE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'END_YEAR' AS Attribute_name,
        END_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'START_YEAR' AS Attribute_name,
        START_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINALLY_AIRED_AS' AS Attribute_name,
        ORIGINALLY_AIRED_AS AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_FAMILY_NUMBER' AS Attribute_name,
        MPM_FAMILY_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_PRODUCT_NUMBER' AS Attribute_name,
        MPM_PRODUCT_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
),
ATTRIBUTES_Completeness1 AS(
SELECT *,
    CASE 
        WHEN ATTRIBUTE_VALUE IS NOT NULL
        THEN 1
        ELSE 0
    END AS IS_PRESENT
FROM ATTRIBUTES_Completeness A

ORDER BY PROFILE_ID
),
IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
),
ATTRIBUTES_Completeness2 AS(
SELECT 
    A.PROFILE_ID,
    A.ATTRIBUTE_NAME,
    IP.ATTRIBUTE_VALUE AS IP_TYPE,
    A.ATTRIBUTE_VALUE,
    A.IS_PRESENT 
FROM ATTRIBUTES_Completeness1 A
LEFT JOIN IP_TYPES IP
ON A.PROFILE_ID=IP.PROFILE_ID
),
Profile_columns as(
SELECT 
    AC.PROFILE_ID,
    AC.ATTRIBUTE_NAME,
    AC.IP_TYPE,
    AC.IS_PRESENT,
    CASE WHEN AM.CRITICALITY IS NULL
         THEN 0
         ELSE 1
    END AS IS_APPLIACABLE,
    AM.Applicability, 
    AM.Criticality, 
    AM.weight
FROM ATTRIBUTES_Completeness2 AC
LEFT JOIN Applicability_Matrix AM ON
AC.IP_TYPE=UPPER(AM.Ip_type)
AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
),

// 3.2). CONCATENATING the [column_name, it's_presence, how important it is for that profile]
GROUPED_DATA AS(
SELECT PROFILE_ID,
    CASE 
        WHEN IS_PRESENT=1 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS ,
    CASE 
        WHEN IS_PRESENT=0 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS_1 
FROM Profile_columns
)

// 3.3). Aggregating all columns together to create a GROUPED_COLUMN_DATA
SELECT 
    PROFILE_ID,
    LISTAGG(IMPORTANT_COLUMS, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS) AS PRESENT_COLUMNS,
    LISTAGG(IMPORTANT_COLUMS_1, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS_1) AS MISSING_COLUMNS
FROM GROUPED_DATA
GROUP BY PROFILE_ID
),

// 4). Finally the PROFILE_HELATH_SUMMARY Table
PROFILE_HELATH_SUMMARY AS(
SELECT 
    SPLIT_PART(P.PROFILE_ID,'/',2) AS ATOM_SEARCH,
    P.PROFILE_ID,
    IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    OVERALL_HEALTH,
    // 4.1). Giving enough space to each column for visiblity
    REGEXP_REPLACE(PRESENT_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS PRESENT_COLUMNS_DIS,
    REGEXP_REPLACE(MISSING_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS MISSING_COLUMNS_DIS
FROM PROFILE_SUMMARY P
LEFT JOIN IMPORTANT_FEATURES I 
ON P.PROFILE_ID=I.PROFILE_ID),
Profile_health_summary as (
SELECT
    //ATOM_SEARCH,
    PROFILE_ID,
    CASE 
        WHEN UPPER(IP_TYPE) 
        NOT IN (
        'SERIES',
        'MINI SERIES',
        'SEASON',
        'PODCAST',
        'MADE FOR VIDEO',
        'EPISODE',
        'SPECIAL',
        'FEATURE',
        'SHORT',
        'TV MOVIE',
        'PILOT',
        'SEGMENT') 
        OR IP_TYPE IS NULL
        THEN 'UNKNOWN'
        ELSE UPPER(IP_TYPE)
    END AS IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    //PARENT_OF,
    ARRAY_SIZE(SPLIT(PRESENT_COLUMNS_DIS,'|')) AS NUM_OF_COL_PRES,
    ARRAY_SIZE(SPLIT(MISSING_COLUMNS_DIS,'|')) AS NUM_OF_COL_MISS,
    OVERALL_HEALTH,
    //PRESENT_COLUMNS_DIS,
    //MISSING_COLUMNS_DIS
FROM PROFILE_HELATH_SUMMARY)
SELECT 
IP_TYPE,
SUM(
CASE WHEN ORPHAN_STATUS='YES' OR HIERARCHY_STATUS = 'NOT VALID' THEN 1 END) AS NOT_VALID_HIERARCHY,
SUM(
CASE WHEN ORPHAN_STATUS='NO' AND HIERARCHY_STATUS='VALID' THEN 1 END) AS VALID_HIERARCHY
FROM Profile_health_summary
GROUP BY IP_TYPE
ORDER BY IP_TYPE;



// Overall Profile Health Categorization

// 1). Merging the Applicability_Matrix with the ATOM profiles:
WITH PROFILE_COM AS(
    SELECT 
        T.NODE_IDENTIFIER,
        T.IP_TYPE,
        Profile_Completeness AS PROFILE_COMPLETENESS 
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    INNER JOIN 
    (WITH Applicability_Matrix AS(
    // 1.1). Applicability_Matrix Created as a Temp table for scoring
    SELECT *
    FROM (
        VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
    ) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
    ),
    
    // 1.2). ATTRIBUTES_Completeness - Gathered only the important columns for tracking
    ATTRIBUTES_Completeness AS(
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_FULL' AS Attribute_name,
            LIBRARY_TITLE_FULL AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_SHORT' AS Attribute_name,
            LIBRARY_TITLE_SHORT AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'IP_TYPE' AS Attribute_name,
            IP_TYPE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
            ORIGINAL_RELEASE_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PI_UUID' AS Attribute_name,
            PI_UUID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_NUMBER' AS Attribute_name,
            MPM_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'NUMBER_OF_EPISODES' AS Attribute_name,
            NUMBER_OF_EPISODES AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'META_ID' AS Attribute_name,
            META_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PROPERTY_ID' AS Attribute_name,
            PROPERTY_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'TURNER_TITLEID' AS Attribute_name,
            TURNER_TITLEID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'GENRE' AS Attribute_name,
            GENRE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'END_YEAR' AS Attribute_name,
            END_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'START_YEAR' AS Attribute_name,
            START_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINALLY_AIRED_AS' AS Attribute_name,
            ORIGINALLY_AIRED_AS AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_FAMILY_NUMBER' AS Attribute_name,
            MPM_FAMILY_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_PRODUCT_NUMBER' AS Attribute_name,
            MPM_PRODUCT_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    ),

    // 1.3). Creating IS_PRESENT column to check the values are there or not
    ATTRIBUTES_Completeness1 AS(
    SELECT *,
        CASE 
            WHEN ATTRIBUTE_VALUE IS NOT NULL
            THEN 1
            ELSE 0
        END AS IS_PRESENT
    FROM ATTRIBUTES_Completeness A
    ORDER BY PROFILE_ID
    ),
    
    // 1.4). Creating the IP_TYPE categories to have a standard format, other than know ip's all the others consider as  "UNKNOWN"
    IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
    ),

    // 1.5). Merging the IP_TYPE table to the ATTRIBUTES_Completeness table
    ATTRIBUTES_Completeness2 AS(
    SELECT 
        A.PROFILE_ID,
        A.ATTRIBUTE_NAME,
        IP.ATTRIBUTE_VALUE AS IP_TYPE,
        A.ATTRIBUTE_VALUE,
        A.IS_PRESENT 
    FROM ATTRIBUTES_Completeness1 A
    LEFT JOIN IP_TYPES IP
    ON A.PROFILE_ID=IP.PROFILE_ID
    ),

    // 1.6). Merging the ATTRIBUTES_Completeness table with Applicability_Matrix to check wheather a particular column is needs for that profile or not, according to the IP_TYPE and the weights are added;
    Attribute_weight as(
    SELECT 
        AC.PROFILE_ID,
        AC.ATTRIBUTE_NAME,
        AC.IP_TYPE,
        //AC.ATTRIBUTE_VALUE,
        AC.IS_PRESENT,
        CASE WHEN AM.CRITICALITY IS NULL
             THEN 0
             ELSE 1
        END AS IS_APPLIACABLE,
        AM.Applicability, 
        AM.Criticality, 
        AM.weight
    FROM ATTRIBUTES_Completeness2 AC
    LEFT JOIN Applicability_Matrix AM ON
    AC.IP_TYPE=UPPER(AM.Ip_type)
    AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
    ),

    // 1.7). Calculating the overall weights for individual profiles
    TOTAL_WEIGHT AS(
    SELECT 
        PROFILE_ID,IP_TYPE,
        SUM(
        CASE WHEN IS_APPLIACABLE=1 AND IS_PRESENT=1
             THEN weight
             ELSE 0
        END) AS T_WEIGHT
    FROM Attribute_weight
    GROUP BY PROFILE_ID,IP_TYPE
    )

    // 1.8). The total_weights are converted into percentage according to the IP_TYPES
    SELECT
        PROFILE_ID,
        T_WEIGHT,
        ROUND(CASE 
            WHEN UPPER(IP_TYPE)='SERIES'
            THEN T_WEIGHT/66*100
            WHEN UPPER(IP_TYPE)='SEASON'
            THEN T_WEIGHT/83*100
            WHEN UPPER(IP_TYPE)='EPISODE'
            THEN T_WEIGHT/76*100
            ELSE T_WEIGHT/64*100
        END,0) AS Profile_Completeness
    FROM TOTAL_WEIGHT) AS weight
    ON T.NODE_IDENTIFIER=weight.PROFILE_ID
),

// Hierarchy Integrity Table (LINEAGE CHECK)
// 2). Taking only required columns from the HIERARCHY Table
Heirachy_Integrity as
(

// 2.1). Taking only required columns from the HIERARCHY Table
WITH ATOM_DATA AS (
    SELECT 
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        E.MPM_NUMBER,
        E.SEASON_MPM_NUMBER,
        E.SERIES_MPM_NUMBER
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.EPISODIC_TITLE_HIERARCHY_VW E
),

-- 2.2) Merging the Atom table with D_TITLE to fill missing SEASON_MPM_NUMBER and SERIES_MPM_NUMBER
HIERARCHY_INFO1 AS (
    SELECT
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        COALESCE(E.MPM_NUMBER,T.MPM_NUMBER) AS EPISODE_MPM_NUMBER,
        COALESCE(E.SEASON_MPM_NUMBER, T.MPM_PRODUCT_NUMBER) AS SEASON_MPM_NUMBER,
        COALESCE(E.SERIES_MPM_NUMBER, T.MPM_FAMILY_NUMBER) AS SERIES_MPM_NUMBER,
        T.PROPERTY_ID,
        T.PI_UUID
    FROM ATOM_DATA E
    LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
        ON E.NODE_IDENTIFIER = T.NODE_IDENTIFIER
),

-- 2.3) Creating lookup table for SERIES_IDENTIFIER
SERIES_LOOKUP AS (
SELECT
    SERIES_MPM_NUMBER,
    MAX(SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
FROM HIERARCHY_INFO1
GROUP BY SERIES_MPM_NUMBER
),

FILLING_IDENTIFIERS AS(
SELECT
    SL.SERIES_MPM_NUMBER,
    T.NODE_IDENTIFIER AS SERIES_IDENTIFIER
FROM SERIES_LOOKUP SL
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    ON SL.SERIES_MPM_NUMBER = T.MPM_NUMBER
WHERE T.NODE_IDENTIFIER IS NOT NULL
),

-- 2.4) Filling missing SERIES_IDENTIFIER and SEASON_IDENTIFIER
HIERARCHY_INFO_F AS(
SELECT
    COALESCE(H.SERIES_IDENTIFIER, SL.SERIES_IDENTIFIER, SSL.SERIES_IDENTIFIER) AS SERIES_IDENTIFIER,
    SSL.SEASON_IDENTIFIER,
    H.NODE_IDENTIFIER,
    H.IP_TYPE,
    H.EPISODE_MPM_NUMBER,
    H.SEASON_MPM_NUMBER,
    COALESCE(H.SERIES_MPM_NUMBER, SSL.SERIES_MPM_NUMBER) AS SERIES_MPM_NUMBER,
    H.PROPERTY_ID,
    H.PI_UUID
FROM HIERARCHY_INFO1 H

LEFT JOIN FILLING_IDENTIFIERS SL
    ON H.SERIES_MPM_NUMBER = SL.SERIES_MPM_NUMBER

LEFT JOIN (
    SELECT
        SEASON_IDENTIFIER,
        SEASON_MPM_NUMBER,
        SERIES_IDENTIFIER,
        SERIES_MPM_NUMBER
    FROM (
        SELECT
            H2.SEASON_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SEASON_IDENTIFIER,
            T.MPM_FAMILY_NUMBER AS SERIES_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SERIES_IDENTIFIER,
            ROW_NUMBER() OVER (
                PARTITION BY H2.SEASON_MPM_NUMBER
                ORDER BY T.NODE_IDENTIFIER
            ) AS RN
        FROM HIERARCHY_INFO1 H2
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H2.SEASON_MPM_NUMBER = T.MPM_NUMBER
    )
    WHERE RN = 1
) SSL
    ON H.SEASON_MPM_NUMBER = SSL.SEASON_MPM_NUMBER)
SELECT 
CASE 
    WHEN HF.NODE_IDENTIFIER=HF.SERIES_IDENTIFIER THEN NULL 
    ELSE HF.SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
HF.SEASON_IDENTIFIER,
HF.NODE_IDENTIFIER,
HF.IP_TYPE,
T.MPM_FAMILY_NUMBER,
T.MPM_PRODUCT_NUMBER,
T.MPM_NUMBER
FROM HIERARCHY_INFO_F HF
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
ON HF.NODE_IDENTIFIER=T.NODE_IDENTIFIER),

// 2.5). Using the HEIRARCHY table creating the VALIDATION CONDITIONS
HEIRARCHY_STATE AS (
SELECT *,
    CASE
        WHEN NODE_IDENTIFIER IN (
            SELECT SERIES_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        WHEN SERIES_IDENTIFIER IN (
            SELECT NODE_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        ELSE 'NOT VALID'
    END AS HIERARCHY_STATUS,
    
// 2.6). Creating Booleans for ORPHAN_STATUS column to know the profile have parent or not
CASE
    WHEN NODE_IDENTIFIER IN 
    (SELECT H.SERIES_IDENTIFIER
     FROM Heirachy_Integrity H)
     THEN 'NO'
    WHEN MPM_FAMILY_NUMBER IS NOT NULL OR MPM_PRODUCT_NUMBER IS NOT NULL
    THEN 'NO'
    WHEN (IP_TYPE IS NULL OR  MPM_NUMBER IS NULL)
    THEN 'YES'
    ELSE 'YES'
END AS ORPHAN_STATUS
FROM Heirachy_Integrity
),
// 2.7). Parent of how many programs:
Heirachy_Integrity AS(
SELECT
CASE 
    WHEN SERIES_IDENTIFIER=NODE_IDENTIFIER THEN NULL 
    ELSE SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
SEASON_IDENTIFIER,
NODE_IDENTIFIER,
IP_TYPE,
MPM_FAMILY_NUMBER,
MPM_PRODUCT_NUMBER,
MPM_NUMBER
FROM Heirachy_Integrity
),
PARENT_LINK AS (
SELECT 
    NODE_IDENTIFIER,
    CASE 
        WHEN SUM(PARENT_COUNT) = 0 THEN 0
        ELSE SUM(PARENT_COUNT) -1
    END AS PARENT_OF
FROM (

    -- Series parent
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(B.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

    UNION ALL

    -- Season parent (avoid duplicate when series = season)
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(A.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SEASON_IDENTIFIER
        AND B.SEASON_IDENTIFIER <> B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

) T
GROUP BY NODE_IDENTIFIER
),
// 2.7). If any of the series related IP_TYPES created alone like not even in HEIRARCHY then that should be considered as ORPHAN and not valid HEIRARCHY status.
STATUS AS(
SELECT 
    PC.NODE_IDENTIFIER,
    PC.IP_TYPE,
    PC.PROFILE_COMPLETENESS,
    COALESCE(HS.HIERARCHY_STATUS, 'NOT_APPLICAPLE') 
    AS HIERARCHY_STATUS,
    COALESCE(HS.ORPHAN_STATUS,'NOT_APPLICAPLE') 
    AS ORPHAN_STATUS,
    PARENT_OF
FROM PROFILE_COM PC
LEFT JOIN HEIRARCHY_STATE HS
ON PC.NODE_IDENTIFIER=HS.NODE_IDENTIFIER
LEFT JOIN PARENT_LINK P
ON PC.NODE_IDENTIFIER=P.NODE_IDENTIFIER
),

// 3). Creating the Overall health column by utilizing three columns (HIERARCHY_STATUS, ORPHAN_STATUS, PROFILE_COMPLETENESS)
PROFILE_SUMMARY AS(
SELECT 
    NODE_IDENTIFIER AS PROFILE_ID,
    IP_TYPE,
    CONCAT(PROFILE_COMPLETENESS,'%') AS PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    CASE 
       WHEN HIERARCHY_STATUS='NOT VALID' THEN 'Critical'
       WHEN ORPHAN_STATUS='YES' THEN 'Critical'
       WHEN PROFILE_COMPLETENESS<70 THEN 'Critical'
       WHEN PROFILE_COMPLETENESS BETWEEN 70 AND 90 THEN 'Normal'
       ELSE 'Healthy'
    END AS OVERALL_HEALTH
FROM STATUS
),

// 3.1). Taking this ATTRIBUTES_Completeness table again to consider only IMPORTANT_FEATURES for creating COLUMN_DESCRIPTION.
IMPORTANT_FEATURES AS (
WITH Applicability_Matrix AS(
SELECT *
FROM (
    VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
),

// Attribute Completeness Matrix (FACT LAYER)
ATTRIBUTES_Completeness AS(
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_FULL' AS Attribute_name,
        LIBRARY_TITLE_FULL AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_SHORT' AS Attribute_name,
        LIBRARY_TITLE_SHORT AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'IP_TYPE' AS Attribute_name,
        IP_TYPE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
        ORIGINAL_RELEASE_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PI_UUID' AS Attribute_name,
        PI_UUID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_NUMBER' AS Attribute_name,
        MPM_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'NUMBER_OF_EPISODES' AS Attribute_name,
        NUMBER_OF_EPISODES AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'META_ID' AS Attribute_name,
        META_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PROPERTY_ID' AS Attribute_name,
        PROPERTY_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'TURNER_TITLEID' AS Attribute_name,
        TURNER_TITLEID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'GENRE' AS Attribute_name,
        GENRE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'END_YEAR' AS Attribute_name,
        END_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'START_YEAR' AS Attribute_name,
        START_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINALLY_AIRED_AS' AS Attribute_name,
        ORIGINALLY_AIRED_AS AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_FAMILY_NUMBER' AS Attribute_name,
        MPM_FAMILY_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_PRODUCT_NUMBER' AS Attribute_name,
        MPM_PRODUCT_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
),
ATTRIBUTES_Completeness1 AS(
SELECT *,
    CASE 
        WHEN ATTRIBUTE_VALUE IS NOT NULL
        THEN 1
        ELSE 0
    END AS IS_PRESENT
FROM ATTRIBUTES_Completeness A

ORDER BY PROFILE_ID
),
IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
),
ATTRIBUTES_Completeness2 AS(
SELECT 
    A.PROFILE_ID,
    A.ATTRIBUTE_NAME,
    IP.ATTRIBUTE_VALUE AS IP_TYPE,
    A.ATTRIBUTE_VALUE,
    A.IS_PRESENT 
FROM ATTRIBUTES_Completeness1 A
LEFT JOIN IP_TYPES IP
ON A.PROFILE_ID=IP.PROFILE_ID
),
Profile_columns as(
SELECT 
    AC.PROFILE_ID,
    AC.ATTRIBUTE_NAME,
    AC.IP_TYPE,
    AC.IS_PRESENT,
    CASE WHEN AM.CRITICALITY IS NULL
         THEN 0
         ELSE 1
    END AS IS_APPLIACABLE,
    AM.Applicability, 
    AM.Criticality, 
    AM.weight
FROM ATTRIBUTES_Completeness2 AC
LEFT JOIN Applicability_Matrix AM ON
AC.IP_TYPE=UPPER(AM.Ip_type)
AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
),

// 3.2). CONCATENATING the [column_name, it's_presence, how important it is for that profile]
GROUPED_DATA AS(
SELECT PROFILE_ID,
    CASE 
        WHEN IS_PRESENT=1 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS ,
    CASE 
        WHEN IS_PRESENT=0 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS_1 
FROM Profile_columns
)

// 3.3). Aggregating all columns together to create a GROUPED_COLUMN_DATA
SELECT 
    PROFILE_ID,
    LISTAGG(IMPORTANT_COLUMS, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS) AS PRESENT_COLUMNS,
    LISTAGG(IMPORTANT_COLUMS_1, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS_1) AS MISSING_COLUMNS
FROM GROUPED_DATA
GROUP BY PROFILE_ID
),

// 4). Finally the PROFILE_HELATH_SUMMARY Table
PROFILE_HELATH_SUMMARY AS(
SELECT 
    SPLIT_PART(P.PROFILE_ID,'/',2) AS ATOM_SEARCH,
    P.PROFILE_ID,
    IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    OVERALL_HEALTH,
    // 4.1). Giving enough space to each column for visiblity
    REGEXP_REPLACE(PRESENT_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS PRESENT_COLUMNS_DIS,
    REGEXP_REPLACE(MISSING_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS MISSING_COLUMNS_DIS
FROM PROFILE_SUMMARY P
LEFT JOIN IMPORTANT_FEATURES I 
ON P.PROFILE_ID=I.PROFILE_ID),
profile_health_summary as (
SELECT
    //ATOM_SEARCH,
    PROFILE_ID,
    CASE 
    WHEN UPPER(IP_TYPE) 
    NOT IN (
    'SERIES',
    'MINI SERIES',
    'SEASON',
    'PODCAST',
    'MADE FOR VIDEO',
    'EPISODE',
    'SPECIAL',
    'FEATURE',
    'SHORT',
    'TV MOVIE',
    'PILOT',
    'SEGMENT') 
    OR IP_TYPE IS NULL
    THEN 'UNKNOWN'
    ELSE UPPER(IP_TYPE)
END AS IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    //PARENT_OF,
    ARRAY_SIZE(SPLIT(PRESENT_COLUMNS_DIS,'|')) AS NUM_OF_COL_PRES,
    ARRAY_SIZE(SPLIT(MISSING_COLUMNS_DIS,'|')) AS NUM_OF_COL_MISS,
    OVERALL_HEALTH,
    //PRESENT_COLUMNS_DIS,
    //MISSING_COLUMNS_DIS
FROM PROFILE_HELATH_SUMMARY),
Final_overall_health as (
SELECT 
IP_TYPE,
SUM(
CASE WHEN OVERALL_HEALTH='Critical' THEN 1 END) AS CRITICAL,
SUM(
CASE WHEN OVERALL_HEALTH='Normal' THEN 1 END) AS NORMAL,
SUM(
CASE WHEN OVERALL_HEALTH='Healthy' THEN 1 END) AS HEALTHY
FROM profile_health_summary
GROUP BY IP_TYPE)
SELECT
IP_TYPE,
COALESCE(CRITICAL,0) AS CRITICAL,
COALESCE(NORMAL,0) AS NORMAL,
COALESCE(HEALTHY,0) AS HEALTHY
FROM Final_overall_health;





// Profile Health Summary from Yesterday’s Creation

// 1). Merging the Applicability_Matrix with the ATOM profiles:
WITH PROFILE_COM AS(
    SELECT 
        T.NODE_IDENTIFIER,
        T.IP_TYPE,
        Profile_Completeness AS PROFILE_COMPLETENESS 
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    INNER JOIN 
    (WITH Applicability_Matrix AS(
    // 1.1). Applicability_Matrix Created as a Temp table for scoring
    SELECT *
    FROM (
        VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
    ) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
    ),
    
    // 1.2). ATTRIBUTES_Completeness - Gathered only the important columns for tracking
    ATTRIBUTES_Completeness AS(
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_FULL' AS Attribute_name,
            LIBRARY_TITLE_FULL AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'LIBRARY_TITLE_SHORT' AS Attribute_name,
            LIBRARY_TITLE_SHORT AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'IP_TYPE' AS Attribute_name,
            IP_TYPE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
            ORIGINAL_RELEASE_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PI_UUID' AS Attribute_name,
            PI_UUID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_NUMBER' AS Attribute_name,
            MPM_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'NUMBER_OF_EPISODES' AS Attribute_name,
            NUMBER_OF_EPISODES AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'META_ID' AS Attribute_name,
            META_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'PROPERTY_ID' AS Attribute_name,
            PROPERTY_ID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'TURNER_TITLEID' AS Attribute_name,
            TURNER_TITLEID AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'GENRE' AS Attribute_name,
            GENRE AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'END_YEAR' AS Attribute_name,
            END_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'START_YEAR' AS Attribute_name,
            START_YEAR AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'ORIGINALLY_AIRED_AS' AS Attribute_name,
            ORIGINALLY_AIRED_AS AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_FAMILY_NUMBER' AS Attribute_name,
            MPM_FAMILY_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
        UNION ALL
        (SELECT 
            NODE_IDENTIFIER AS Profile_id,
            'MPM_PRODUCT_NUMBER' AS Attribute_name,
            MPM_PRODUCT_NUMBER AS Attribute_value
        FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    ),

    // 1.3). Creating IS_PRESENT column to check the values are there or not
    ATTRIBUTES_Completeness1 AS(
    SELECT *,
        CASE 
            WHEN ATTRIBUTE_VALUE IS NOT NULL
            THEN 1
            ELSE 0
        END AS IS_PRESENT
    FROM ATTRIBUTES_Completeness A
    ORDER BY PROFILE_ID
    ),
    
    // 1.4). Creating the IP_TYPE categories to have a standard format, other than know ip's all the others consider as  "UNKNOWN"
    IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
    ),

    // 1.5). Merging the IP_TYPE table to the ATTRIBUTES_Completeness table
    ATTRIBUTES_Completeness2 AS(
    SELECT 
        A.PROFILE_ID,
        A.ATTRIBUTE_NAME,
        IP.ATTRIBUTE_VALUE AS IP_TYPE,
        A.ATTRIBUTE_VALUE,
        A.IS_PRESENT 
    FROM ATTRIBUTES_Completeness1 A
    LEFT JOIN IP_TYPES IP
    ON A.PROFILE_ID=IP.PROFILE_ID
    ),

    // 1.6). Merging the ATTRIBUTES_Completeness table with Applicability_Matrix to check wheather a particular column is needs for that profile or not, according to the IP_TYPE and the weights are added;
    Attribute_weight as(
    SELECT 
        AC.PROFILE_ID,
        AC.ATTRIBUTE_NAME,
        AC.IP_TYPE,
        //AC.ATTRIBUTE_VALUE,
        AC.IS_PRESENT,
        CASE WHEN AM.CRITICALITY IS NULL
             THEN 0
             ELSE 1
        END AS IS_APPLIACABLE,
        AM.Applicability, 
        AM.Criticality, 
        AM.weight
    FROM ATTRIBUTES_Completeness2 AC
    LEFT JOIN Applicability_Matrix AM ON
    AC.IP_TYPE=UPPER(AM.Ip_type)
    AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
    ),

    // 1.7). Calculating the overall weights for individual profiles
    TOTAL_WEIGHT AS(
    SELECT 
        PROFILE_ID,IP_TYPE,
        SUM(
        CASE WHEN IS_APPLIACABLE=1 AND IS_PRESENT=1
             THEN weight
             ELSE 0
        END) AS T_WEIGHT
    FROM Attribute_weight
    GROUP BY PROFILE_ID,IP_TYPE
    )

    // 1.8). The total_weights are converted into percentage according to the IP_TYPES
    SELECT
        PROFILE_ID,
        T_WEIGHT,
        ROUND(CASE 
            WHEN UPPER(IP_TYPE)='SERIES'
            THEN T_WEIGHT/66*100
            WHEN UPPER(IP_TYPE)='SEASON'
            THEN T_WEIGHT/83*100
            WHEN UPPER(IP_TYPE)='EPISODE'
            THEN T_WEIGHT/76*100
            ELSE T_WEIGHT/64*100
        END,0) AS Profile_Completeness
    FROM TOTAL_WEIGHT) AS weight
    ON T.NODE_IDENTIFIER=weight.PROFILE_ID
),

// Hierarchy Integrity Table (LINEAGE CHECK)
// 2). Taking only required columns from the HIERARCHY Table
Heirachy_Integrity as
(

// 2.1). Taking only required columns from the HIERARCHY Table
WITH ATOM_DATA AS (
    SELECT 
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        E.MPM_NUMBER,
        E.SEASON_MPM_NUMBER,
        E.SERIES_MPM_NUMBER
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.EPISODIC_TITLE_HIERARCHY_VW E
),

-- 2.2) Merging the Atom table with D_TITLE to fill missing SEASON_MPM_NUMBER and SERIES_MPM_NUMBER
HIERARCHY_INFO1 AS (
    SELECT
        E.SERIES_IDENTIFIER,
        E.NODE_IDENTIFIER,
        E.IP_TYPE,
        COALESCE(E.MPM_NUMBER,T.MPM_NUMBER) AS EPISODE_MPM_NUMBER,
        COALESCE(E.SEASON_MPM_NUMBER, T.MPM_PRODUCT_NUMBER) AS SEASON_MPM_NUMBER,
        COALESCE(E.SERIES_MPM_NUMBER, T.MPM_FAMILY_NUMBER) AS SERIES_MPM_NUMBER,
        T.PROPERTY_ID,
        T.PI_UUID
    FROM ATOM_DATA E
    LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
        ON E.NODE_IDENTIFIER = T.NODE_IDENTIFIER
),

-- 2.3) Creating lookup table for SERIES_IDENTIFIER
SERIES_LOOKUP AS (
SELECT
    SERIES_MPM_NUMBER,
    MAX(SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
FROM HIERARCHY_INFO1
GROUP BY SERIES_MPM_NUMBER
),

FILLING_IDENTIFIERS AS(
SELECT
    SL.SERIES_MPM_NUMBER,
    T.NODE_IDENTIFIER AS SERIES_IDENTIFIER
FROM SERIES_LOOKUP SL
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
    ON SL.SERIES_MPM_NUMBER = T.MPM_NUMBER
WHERE T.NODE_IDENTIFIER IS NOT NULL
),

-- 2.4) Filling missing SERIES_IDENTIFIER and SEASON_IDENTIFIER
HIERARCHY_INFO_F AS(
SELECT
    COALESCE(H.SERIES_IDENTIFIER, SL.SERIES_IDENTIFIER, SSL.SERIES_IDENTIFIER) AS SERIES_IDENTIFIER,
    SSL.SEASON_IDENTIFIER,
    H.NODE_IDENTIFIER,
    H.IP_TYPE,
    H.EPISODE_MPM_NUMBER,
    H.SEASON_MPM_NUMBER,
    COALESCE(H.SERIES_MPM_NUMBER, SSL.SERIES_MPM_NUMBER) AS SERIES_MPM_NUMBER,
    H.PROPERTY_ID,
    H.PI_UUID
FROM HIERARCHY_INFO1 H

LEFT JOIN FILLING_IDENTIFIERS SL
    ON H.SERIES_MPM_NUMBER = SL.SERIES_MPM_NUMBER

LEFT JOIN (
    SELECT
        SEASON_IDENTIFIER,
        SEASON_MPM_NUMBER,
        SERIES_IDENTIFIER,
        SERIES_MPM_NUMBER
    FROM (
        SELECT
            H2.SEASON_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SEASON_IDENTIFIER,
            T.MPM_FAMILY_NUMBER AS SERIES_MPM_NUMBER,
            T.NODE_IDENTIFIER AS SERIES_IDENTIFIER,
            ROW_NUMBER() OVER (
                PARTITION BY H2.SEASON_MPM_NUMBER
                ORDER BY T.NODE_IDENTIFIER
            ) AS RN
        FROM HIERARCHY_INFO1 H2
        LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
            ON H2.SEASON_MPM_NUMBER = T.MPM_NUMBER
    )
    WHERE RN = 1
) SSL
    ON H.SEASON_MPM_NUMBER = SSL.SEASON_MPM_NUMBER)
SELECT 
CASE 
    WHEN HF.NODE_IDENTIFIER=HF.SERIES_IDENTIFIER THEN NULL 
    ELSE HF.SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
HF.SEASON_IDENTIFIER,
HF.NODE_IDENTIFIER,
HF.IP_TYPE,
T.MPM_FAMILY_NUMBER,
T.MPM_PRODUCT_NUMBER,
T.MPM_NUMBER
FROM HIERARCHY_INFO_F HF
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
ON HF.NODE_IDENTIFIER=T.NODE_IDENTIFIER),

// 2.5). Using the HEIRARCHY table creating the VALIDATION CONDITIONS
HEIRARCHY_STATE AS (
SELECT *,
    CASE
        WHEN NODE_IDENTIFIER IN (
            SELECT SERIES_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        WHEN SERIES_IDENTIFIER IN (
            SELECT NODE_IDENTIFIER
            FROM Heirachy_Integrity)
            THEN 'VALID'
        ELSE 'NOT VALID'
    END AS HIERARCHY_STATUS,
    
// 2.6). Creating Booleans for ORPHAN_STATUS column to know the profile have parent or not
CASE
    WHEN NODE_IDENTIFIER IN 
    (SELECT H.SERIES_IDENTIFIER
     FROM Heirachy_Integrity H)
     THEN 'NO'
    WHEN MPM_FAMILY_NUMBER IS NOT NULL OR MPM_PRODUCT_NUMBER IS NOT NULL
    THEN 'NO'
    WHEN (IP_TYPE IS NULL OR  MPM_NUMBER IS NULL)
    THEN 'YES'
    ELSE 'YES'
END AS ORPHAN_STATUS
FROM Heirachy_Integrity
),
// 2.7). Parent of how many programs:
Heirachy_Integrity AS(
SELECT
CASE 
    WHEN SERIES_IDENTIFIER=NODE_IDENTIFIER THEN NULL 
    ELSE SERIES_IDENTIFIER 
END AS SERIES_IDENTIFIER,
SEASON_IDENTIFIER,
NODE_IDENTIFIER,
IP_TYPE,
MPM_FAMILY_NUMBER,
MPM_PRODUCT_NUMBER,
MPM_NUMBER
FROM Heirachy_Integrity
),
PARENT_LINK AS (
SELECT 
    NODE_IDENTIFIER,
    CASE 
        WHEN SUM(PARENT_COUNT) = 0 THEN 0
        ELSE SUM(PARENT_COUNT) -1
    END AS PARENT_OF
FROM (

    -- Series parent
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(B.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

    UNION ALL

    -- Season parent (avoid duplicate when series = season)
    SELECT 
        A.NODE_IDENTIFIER,
        COUNT(A.NODE_IDENTIFIER) AS PARENT_COUNT
    FROM Heirachy_Integrity A
    LEFT JOIN Heirachy_Integrity B
        ON A.NODE_IDENTIFIER = B.SEASON_IDENTIFIER
        AND B.SEASON_IDENTIFIER <> B.SERIES_IDENTIFIER
    GROUP BY A.NODE_IDENTIFIER

) T
GROUP BY NODE_IDENTIFIER
),
// 2.7). If any of the series related IP_TYPES created alone like not even in HEIRARCHY then that should be considered as ORPHAN and not valid HEIRARCHY status.
STATUS AS(
SELECT 
    PC.NODE_IDENTIFIER,
    PC.IP_TYPE,
    PC.PROFILE_COMPLETENESS,
    COALESCE(HS.HIERARCHY_STATUS, 'NOT_APPLICAPLE') 
    AS HIERARCHY_STATUS,
    COALESCE(HS.ORPHAN_STATUS,'NOT_APPLICAPLE') 
    AS ORPHAN_STATUS,
    PARENT_OF
FROM PROFILE_COM PC
LEFT JOIN HEIRARCHY_STATE HS
ON PC.NODE_IDENTIFIER=HS.NODE_IDENTIFIER
LEFT JOIN PARENT_LINK P
ON PC.NODE_IDENTIFIER=P.NODE_IDENTIFIER
),

// 3). Creating the Overall health column by utilizing three columns (HIERARCHY_STATUS, ORPHAN_STATUS, PROFILE_COMPLETENESS)
PROFILE_SUMMARY AS(
SELECT 
    NODE_IDENTIFIER AS PROFILE_ID,
    IP_TYPE,
    CONCAT(PROFILE_COMPLETENESS,'%') AS PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    CASE 
       WHEN HIERARCHY_STATUS='NOT VALID' THEN 'Critical'
       WHEN ORPHAN_STATUS='YES' THEN 'Critical'
       WHEN PROFILE_COMPLETENESS<70 THEN 'Critical'
       WHEN PROFILE_COMPLETENESS BETWEEN 70 AND 90 THEN 'Normal'
       ELSE 'Healthy'
    END AS OVERALL_HEALTH
FROM STATUS
),

// 3.1). Taking this ATTRIBUTES_Completeness table again to consider only IMPORTANT_FEATURES for creating COLUMN_DESCRIPTION.
IMPORTANT_FEATURES AS (
WITH Applicability_Matrix AS(
SELECT *
FROM (
    VALUES
        ('Series',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Series',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Series',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Series',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Series',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Series',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Series',  'META_ID',                'Optional',  'Low',       3),
        ('Series',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Series',  'GENRE',                  'Optional',  'Low',       2),
        ('Series',  'END_YEAR',               'Optional',  'Low',       1),
        ('Series',  'START_YEAR',             'Optional',  'Low',       1),

        ('Season',  'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Season',  'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Season',  'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Season',  'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Season',  'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Season',  'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Season',  'MPM_FAMILY_NUMBER',      'Mandatory', 'Critical',  9),
        ('Season',  'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Season',  'NUMBER_OF_EPISODES',     'Optional',  'Low',       4),
        ('Season',  'META_ID',                'Optional',  'Low',       3),
        ('Season',  'PROPERTY_ID',            'Optional',  'Low',       3),
        ('Season',  'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Season',  'GENRE',                  'Optional',  'Low',       2),
        ('Season',  'END_YEAR',               'Optional',  'Low',       1),
        ('Season',  'START_YEAR',             'Optional',  'Low',       1),

        ('Episode', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Episode', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Episode', 'IP_TYPE',                'Mandatory', 'Critical', 10),
        ('Episode', 'ORIGINALLY_AIRED_AS',    'Optional',  'Medium',    5),
        ('Episode', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Episode', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Episode', 'MPM_PRODUCT_NUMBER',     'Mandatory', 'Critical',  8),
        ('Episode', 'META_ID',                'Optional',  'Low',       3),
        ('Episode',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Episode', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Episode', 'GENRE',                  'Optional',  'Low',       2),

        ('Unknown', 'LIBRARY_TITLE_FULL',     'Mandatory', 'Critical', 10),
        ('Unknown', 'LIBRARY_TITLE_SHORT',    'Mandatory', 'Critical',  9),
        ('Unknown', 'IP_TYPE',                'Optional', 'Low', 2),
        ('Unknown', 'ORIGINAL_RELEASE_YEAR',  'Optional',  'Medium',    5),
        ('Unknown', 'PI_UUID',                'Mandatory', 'Critical', 10),
        ('Unknown', 'MPM_FAMILY_NUMBER',      'Optional',  'Medium',    9),
        ('Unknown', 'MPM_NUMBER',             'Mandatory', 'Critical',  8),
        ('Unknown', 'META_ID',                'Optional',  'Low',       3),
        ('Unknown',  'PROPERTY_ID',           'Optional',  'Low',       3),
        ('Unknown', 'TURNER_TITLEID',         'Optional',  'Low',       3),
        ('Unknown', 'GENRE',                  'Optional',  'Low',       2)
) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
),

// Attribute Completeness Matrix (FACT LAYER)
ATTRIBUTES_Completeness AS(
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_FULL' AS Attribute_name,
        LIBRARY_TITLE_FULL AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'LIBRARY_TITLE_SHORT' AS Attribute_name,
        LIBRARY_TITLE_SHORT AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'IP_TYPE' AS Attribute_name,
        IP_TYPE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINAL_RELEASE_YEAR' AS Attribute_name,
        ORIGINAL_RELEASE_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PI_UUID' AS Attribute_name,
        PI_UUID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_NUMBER' AS Attribute_name,
        MPM_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'NUMBER_OF_EPISODES' AS Attribute_name,
        NUMBER_OF_EPISODES AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'META_ID' AS Attribute_name,
        META_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'PROPERTY_ID' AS Attribute_name,
        PROPERTY_ID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'TURNER_TITLEID' AS Attribute_name,
        TURNER_TITLEID AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'GENRE' AS Attribute_name,
        GENRE AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'END_YEAR' AS Attribute_name,
        END_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'START_YEAR' AS Attribute_name,
        START_YEAR AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'ORIGINALLY_AIRED_AS' AS Attribute_name,
        ORIGINALLY_AIRED_AS AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_FAMILY_NUMBER' AS Attribute_name,
        MPM_FAMILY_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
    UNION ALL
    (SELECT 
        NODE_IDENTIFIER AS Profile_id,
        'MPM_PRODUCT_NUMBER' AS Attribute_name,
        MPM_PRODUCT_NUMBER AS Attribute_value
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE)
),
ATTRIBUTES_Completeness1 AS(
SELECT *,
    CASE 
        WHEN ATTRIBUTE_VALUE IS NOT NULL
        THEN 1
        ELSE 0
    END AS IS_PRESENT
FROM ATTRIBUTES_Completeness A

ORDER BY PROFILE_ID
),
IP_TYPES AS(
    SELECT 
        PROFILE_ID,
        CASE 
            WHEN ATTRIBUTE_VALUE
            IN ('Series')
            THEN 'SERIES'
            WHEN ATTRIBUTE_VALUE
            IN ('Season')
            THEN 'SEASON'
            WHEN ATTRIBUTE_VALUE
            IN ('Episode')
            THEN 'EPISODE'
            WHEN ATTRIBUTE_VALUE 
            IN ('Special',
                'Game',
                'Publishing',
                'Short',
                'Music',
                'Feature',
                'Budget',
                'Motion Comic',
                'TV Sales Package',
                'TV Movie','Podcast',
                'Development',
                'Business Unit MPM',
                'Group IP Non-WHE',
                'Application',
                'Made For Video',
                'Mini Series',
                'Presentation',
                'Pilot',
                'Live Stage',
                'Ancillary/Derivative',
                'Non-IP',
                'Term Deal',
                'Group IP WHE',
                'Consumer Products',
                'Pilot',
                'Segment',
                'Supplemental') OR ATTRIBUTE_VALUE IS NULL
            THEN 'UNKNOWN'
             ELSE UPPER(ATTRIBUTE_VALUE)
        END AS ATTRIBUTE_VALUE
    FROM ATTRIBUTES_Completeness1
    WHERE ATTRIBUTE_NAME='IP_TYPE'
),
ATTRIBUTES_Completeness2 AS(
SELECT 
    A.PROFILE_ID,
    A.ATTRIBUTE_NAME,
    IP.ATTRIBUTE_VALUE AS IP_TYPE,
    A.ATTRIBUTE_VALUE,
    A.IS_PRESENT 
FROM ATTRIBUTES_Completeness1 A
LEFT JOIN IP_TYPES IP
ON A.PROFILE_ID=IP.PROFILE_ID
),
Profile_columns as(
SELECT 
    AC.PROFILE_ID,
    AC.ATTRIBUTE_NAME,
    AC.IP_TYPE,
    AC.IS_PRESENT,
    CASE WHEN AM.CRITICALITY IS NULL
         THEN 0
         ELSE 1
    END AS IS_APPLIACABLE,
    AM.Applicability, 
    AM.Criticality, 
    AM.weight
FROM ATTRIBUTES_Completeness2 AC
LEFT JOIN Applicability_Matrix AM ON
AC.IP_TYPE=UPPER(AM.Ip_type)
AND AC.ATTRIBUTE_NAME=AM.ATTRIBUTE_NAME
),

// 3.2). CONCATENATING the [column_name, it's_presence, how important it is for that profile]
GROUPED_DATA AS(
SELECT PROFILE_ID,
    CASE 
        WHEN IS_PRESENT=1 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS ,
    CASE 
        WHEN IS_PRESENT=0 AND CRITICALITY IS NOT NULL
        THEN CONCAT('[','COLUMN: ',ATTRIBUTE_NAME,', ','CRITICALITY: ',COALESCE(CRITICALITY,'NA'),']') 
        ELSE ''
    END AS IMPORTANT_COLUMS_1 
FROM Profile_columns
)

// 3.3). Aggregating all columns together to create a GROUPED_COLUMN_DATA
SELECT 
    PROFILE_ID,
    LISTAGG(IMPORTANT_COLUMS, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS) AS PRESENT_COLUMNS,
    LISTAGG(IMPORTANT_COLUMS_1, ' | ')
        WITHIN GROUP (ORDER BY IMPORTANT_COLUMS_1) AS MISSING_COLUMNS
FROM GROUPED_DATA
GROUP BY PROFILE_ID
),

// 4). Finally the PROFILE_HELATH_SUMMARY Table
PROFILE_HELATH_SUMMARY AS(
SELECT 
    SPLIT_PART(P.PROFILE_ID,'/',2) AS ATOM_SEARCH,
    P.PROFILE_ID,
    IP_TYPE,
    PROFILE_COMPLETENESS,
    HIERARCHY_STATUS,
    ORPHAN_STATUS,
    PARENT_OF,
    OVERALL_HEALTH,
    // 4.1). Giving enough space to each column for visiblity
    REGEXP_REPLACE(PRESENT_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS PRESENT_COLUMNS_DIS,
    REGEXP_REPLACE(MISSING_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '') AS MISSING_COLUMNS_DIS
FROM PROFILE_SUMMARY P
LEFT JOIN IMPORTANT_FEATURES I 
ON P.PROFILE_ID=I.PROFILE_ID),
profile_health_summary as (
SELECT
    //ATOM_SEARCH,
    P.PROFILE_ID,
    CASE 
    WHEN UPPER(P.IP_TYPE) 
    NOT IN (
    'SERIES',
    'MINI SERIES',
    'SEASON',
    'PODCAST',
    'MADE FOR VIDEO',
    'EPISODE',
    'SPECIAL',
    'FEATURE',
    'SHORT',
    'TV MOVIE',
    'PILOT',
    'SEGMENT') 
    OR P.IP_TYPE IS NULL
    THEN 'UNKNOWN'
    ELSE UPPER(P.IP_TYPE)
    END AS IP_TYPE,
    P.PROFILE_COMPLETENESS,
    CASE WHEN P.HIERARCHY_STATUS='NOT VALID' AND P.ORPHAN_STATUS='YES' THEN 'NOT_VALID'
         WHEN P.HIERARCHY_STATUS='NOT VALID' AND P.ORPHAN_STATUS='NO' THEN 'NOT_VALID'
         WHEN P.HIERARCHY_STATUS='VALID' AND P.ORPHAN_STATUS='YES' THEN 'NOT_VALID'
    ELSE 'VALID'
    END AS HIERARCHY_STATUS,
    //PARENT_OF,
    ARRAY_SIZE(SPLIT(PRESENT_COLUMNS_DIS,'|')) AS NUM_OF_COL_PRES,
    ARRAY_SIZE(SPLIT(MISSING_COLUMNS_DIS,'|')) AS NUM_OF_COL_MISS,
    OVERALL_HEALTH,
    T.RELTIO_LAST_UPDATED_TS AS PROFILE_UPDATED_DATE,
    T.RELTIO_LAST_UPDATED_BY AS UPDATED_BY
    //PRESENT_COLUMNS_DIS,
    //MISSING_COLUMNS_DIS
FROM PROFILE_HELATH_SUMMARY P
LEFT JOIN BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
ON P.PROFILE_ID=T.NODE_IDENTIFIER)
SELECT *
FROM profile_health_summary
WHERE DATE(PROFILE_UPDATED_DATE)=(
SELECT 
MAX(DATE(RELTIO_LAST_UPDATED_TS))
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE
);


-- 1. incompleteness, 2. leading articles 3. special characters.

---------1.) Title, 

SELECT 
SUM(CASE WHEN TITLE IS NULL OR COALESCE(TRIM(TITLE),'')=''
     THEN 1
     ELSE 0
     END) AS Incomplete_Titles,
SUM(CASE
     WHEN TITLE RLIKE '(^|[^0-9])(19|20)[0-9]{2}([^0-9]|$)'
     THEN 1
     ELSE 0
END) AS Titles_with_Release_Year
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE;


------------------short title

SELECT 
SUM(CASE WHEN LIBRARY_TITLE_SHORT IS NULL OR COALESCE(TRIM(LIBRARY_TITLE_SHORT),'')=''
     THEN 1
     ELSE 0
     END) AS Incomplete_Library_Short_Titles,

SUM(
  CASE
    WHEN LIBRARY_TITLE_SHORT IS NOT NULL
    AND UPPER(LIBRARY_TITLE_SHORT) LIKE 'THE %' OR 
        UPPER(LIBRARY_TITLE_SHORT) LIKE 'AN %' OR 
        UPPER(LIBRARY_TITLE_SHORT) LIKE 'A %'
    THEN 1
    ELSE 0
  END
) AS Leading_Article_Library_Title_Short,

SUM(CASE WHEN LIBRARY_TITLE_SHORT IS NOT NULL
     AND REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', '') != REGEXP_REPLACE(REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', ''), '[^ -~]', '')
   OR REGEXP_LIKE(LIBRARY_TITLE_SHORT, $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$)
     THEN 1
     ELSE 0
     END) AS Special_Char_In_Library_short_Titles,

SUM(CASE WHEN LENGTH(LIBRARY_TITLE_SHORT)>40
        THEN 1
        ELSE 0
        END) AS Over_40_Char_limit_length
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE;

-----------------------Library title

SELECT 
SUM(CASE WHEN LIBRARY_TITLE_FULL IS NULL OR COALESCE(TRIM(LIBRARY_TITLE_SHORT),'')=''
     THEN 1
     ELSE 0
     END) AS Incomplete_Library_Full_Titles,

SUM(
  CASE
    WHEN LIBRARY_TITLE_FULL IS NOT NULL
    AND UPPER(LIBRARY_TITLE_FULL) LIKE 'THE %' OR 
        UPPER(LIBRARY_TITLE_FULL) LIKE 'AN %' OR 
        UPPER(LIBRARY_TITLE_FULL) LIKE 'A %'
    THEN 1
    ELSE 0
  END
) AS Leading_Article_Library_Title_Full,

SUM(CASE WHEN LIBRARY_TITLE_FULL IS NOT NULL
     AND REGEXP_REPLACE(LIBRARY_TITLE_FULL, '[\u2018\u2019\u201C\u201D]', '') != REGEXP_REPLACE(REGEXP_REPLACE(LIBRARY_TITLE_FULL, '[\u2018\u2019\u201C\u201D]', ''), '[^ -~]', '')
   OR REGEXP_LIKE(LIBRARY_TITLE_FULL, $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$)
     THEN 1
     ELSE 0
     END) AS Special_Char_In_Library_Full_Titles
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE;


-----------------------------------------------------------------------------------

-- overall_title_completeness_view:

WITH rules AS (
    SELECT
        NODE_IDENTIFIER,
        TITLE,
        LIBRARY_TITLE_SHORT,
        LIBRARY_TITLE_FULL,

        /* -----------------------------
           1) TITLE rules (same as yours)
        ------------------------------*/
        CASE
            WHEN TITLE IS NULL OR COALESCE(TRIM(TITLE), '') = '' THEN 1 ELSE 0
        END AS F_TITLE_INCOMPLETE,

        CASE
            WHEN TITLE RLIKE '(^|[^0-9])(19|20)[0-9]{2}([^0-9]|$)' THEN 1 ELSE 0
        END AS F_TITLE_HAS_YEAR,

        /* ----------------------------------------
           2) LIBRARY_TITLE_SHORT rules (same logic)
        -----------------------------------------*/
        CASE
            WHEN LIBRARY_TITLE_SHORT IS NULL OR COALESCE(TRIM(LIBRARY_TITLE_SHORT), '') = '' THEN 1 ELSE 0
        END AS F_LTS_INCOMPLETE,

        CASE
            WHEN LIBRARY_TITLE_SHORT IS NOT NULL
             AND (
                    UPPER(LIBRARY_TITLE_SHORT) LIKE 'THE %'
                 OR UPPER(LIBRARY_TITLE_SHORT) LIKE 'AN %'
                 OR UPPER(LIBRARY_TITLE_SHORT) LIKE 'A %'
                 )
            THEN 1 ELSE 0
        END AS F_LTS_LEADING_ARTICLE,

        CASE
            WHEN LIBRARY_TITLE_SHORT IS NOT NULL
             AND (
                    (
                      REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', '')
                      != REGEXP_REPLACE(
                            REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', ''),
                            '[^ -~]',
                            ''
                         )
                    )
                 OR REGEXP_LIKE(
                        LIBRARY_TITLE_SHORT,
                        $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$
                    )
                 )
            THEN 1 ELSE 0
        END AS F_LTS_SPECIAL_CHAR,

        CASE
            WHEN LENGTH(LIBRARY_TITLE_SHORT) > 40 THEN 1 ELSE 0
        END AS F_LTS_OVER_40,

        /* ----------------------------------------
           3) LIBRARY_TITLE_FULL rules (same logic)
        -----------------------------------------*/
        CASE
            WHEN LIBRARY_TITLE_FULL IS NULL OR COALESCE(TRIM(LIBRARY_TITLE_FULL), '') = '' THEN 1 ELSE 0
        END AS F_LTF_INCOMPLETE,

        CASE
            WHEN LIBRARY_TITLE_FULL IS NOT NULL
             AND (
                    UPPER(LIBRARY_TITLE_FULL) LIKE 'THE %'
                 OR UPPER(LIBRARY_TITLE_FULL) LIKE 'AN %'
                 OR UPPER(LIBRARY_TITLE_FULL) LIKE 'A %'
                 )
            THEN 1 ELSE 0
        END AS F_LTF_LEADING_ARTICLE,

        CASE
            WHEN LIBRARY_TITLE_FULL IS NOT NULL
             AND (
                    (
                      REGEXP_REPLACE(LIBRARY_TITLE_FULL, '[\u2018\u2019\u201C\u201D]', '')
                      != REGEXP_REPLACE(
                            REGEXP_REPLACE(LIBRARY_TITLE_FULL, '[\u2018\u2019\u201C\u201D]', ''),
                            '[^ -~]',
                            ''
                         )
                    )
                 OR REGEXP_LIKE(
                        LIBRARY_TITLE_FULL,
                        $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$
                    )
                 )
            THEN 1 ELSE 0
        END AS F_LTF_SPECIAL_CHAR

    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE
),
FINAL_COMPLETENESS_TABLE as (
SELECT
    NODE_IDENTIFIER,

    /* ✅ Always show the actual title fields */
    TITLE,
    LIBRARY_TITLE_SHORT,
    LIBRARY_TITLE_FULL,

    /* Optional: keep your "issue value columns" for export */
    CASE WHEN F_TITLE_INCOMPLETE = 1 THEN TITLE ELSE NULL END AS Incomplete_Titles,
    CASE WHEN F_TITLE_HAS_YEAR   = 1 THEN TITLE ELSE NULL END AS Titles_with_Release_Year,

    CASE WHEN F_LTS_INCOMPLETE       = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Incomplete_Library_Short_Titles,
    CASE WHEN F_LTS_LEADING_ARTICLE  = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Leading_Article_Library_Title_Short,
    CASE WHEN F_LTS_SPECIAL_CHAR     = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Special_Char_In_Library_short_Titles,
    CASE WHEN F_LTS_OVER_40          = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Over_40_Char_limit_length,

    CASE WHEN F_LTF_INCOMPLETE      = 1 THEN LIBRARY_TITLE_FULL ELSE NULL END AS Incomplete_Library_Full_Titles,
    CASE WHEN F_LTF_LEADING_ARTICLE = 1 THEN LIBRARY_TITLE_FULL ELSE NULL END AS Leading_Article_Library_Title_Full,
    CASE WHEN F_LTF_SPECIAL_CHAR    = 1 THEN LIBRARY_TITLE_FULL ELSE NULL END AS Special_Char_In_Library_Full_Titles,

    /* ✅ Flag column (profile status) */
    CASE
        WHEN (F_TITLE_INCOMPLETE = 1 OR F_LTS_INCOMPLETE = 1 OR F_LTF_INCOMPLETE = 1)
            THEN 'INCOMPLETE'
        WHEN (
                F_TITLE_HAS_YEAR = 1
             OR F_LTS_LEADING_ARTICLE = 1 OR F_LTS_SPECIAL_CHAR = 1 OR F_LTS_OVER_40 = 1
             OR F_LTF_LEADING_ARTICLE = 1 OR F_LTF_SPECIAL_CHAR = 1
             )
            THEN 'AT_RISK'
        ELSE 'COMPLETE'
    END AS Profile_Status,

    /* ✅ Command column: list the issues triggered */
    ARRAY_TO_STRING(
        ARRAY_COMPACT(
            ARRAY_CONSTRUCT(
                IFF(F_TITLE_INCOMPLETE = 1, 'TITLE:Incomplete', NULL),
                IFF(F_TITLE_HAS_YEAR   = 1, 'TITLE:Release_Year', NULL),

                IFF(F_LTS_INCOMPLETE      = 1, 'LTS:Incomplete', NULL),
                IFF(F_LTS_LEADING_ARTICLE = 1, 'LTS:Leading_Article', NULL),
                IFF(F_LTS_SPECIAL_CHAR    = 1, 'LTS:Special_Char', NULL),
                IFF(F_LTS_OVER_40         = 1, 'LTS:Over_40', NULL),

                IFF(F_LTF_INCOMPLETE      = 1, 'LTF:Incomplete', NULL),
                IFF(F_LTF_LEADING_ARTICLE = 1, 'LTF:Leading_Article', NULL),
                IFF(F_LTF_SPECIAL_CHAR    = 1, 'LTF:Special_Char', NULL)
            )
        ),
        '; '
    ) AS Command_Issue

FROM rules)
SELECT 
Profile_Status,
COUNT(Profile_Status) AS TITLES_STATUS
FROM FINAL_COMPLETENESS_TABLE
GROUP BY Profile_Status
ORDER BY COUNT(Profile_Status) DESC;





----------------------------------------------------


WITH rules AS (
    SELECT
        NODE_IDENTIFIER,
        TITLE,
        LIBRARY_TITLE_SHORT,
        LIBRARY_TITLE_FULL,

        /* -----------------------------
           1) TITLE rules (same as yours)
        ------------------------------*/
        CASE
            WHEN TITLE IS NULL OR COALESCE(TRIM(TITLE), '') = '' THEN 1 ELSE 0
        END AS F_TITLE_INCOMPLETE,

        CASE
            WHEN TITLE RLIKE '(^|[^0-9])(19|20)[0-9]{2}([^0-9]|$)' THEN 1 ELSE 0
        END AS F_TITLE_HAS_YEAR,

        /* ----------------------------------------
           2) LIBRARY_TITLE_SHORT rules (same logic)
        -----------------------------------------*/
        CASE
            WHEN LIBRARY_TITLE_SHORT IS NULL OR COALESCE(TRIM(LIBRARY_TITLE_SHORT), '') = '' THEN 1 ELSE 0
        END AS F_LTS_INCOMPLETE,

        CASE
            WHEN LIBRARY_TITLE_SHORT IS NOT NULL
             AND (
                    UPPER(LIBRARY_TITLE_SHORT) LIKE 'THE %'
                 OR UPPER(LIBRARY_TITLE_SHORT) LIKE 'AN %'
                 OR UPPER(LIBRARY_TITLE_SHORT) LIKE 'A %'
                 )
            THEN 1 ELSE 0
        END AS F_LTS_LEADING_ARTICLE,

        CASE
            WHEN LIBRARY_TITLE_SHORT IS NOT NULL
             AND (
                    (
                      REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', '')
                      != REGEXP_REPLACE(
                            REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', ''),
                            '[^ -~]',
                            ''
                         )
                    )
                 OR REGEXP_LIKE(
                        LIBRARY_TITLE_SHORT,
                        $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$
                    )
                 )
            THEN 1 ELSE 0
        END AS F_LTS_SPECIAL_CHAR,

        CASE
            WHEN LENGTH(LIBRARY_TITLE_SHORT) > 40 THEN 1 ELSE 0
        END AS F_LTS_OVER_40,

        /* ----------------------------------------
           3) LIBRARY_TITLE_FULL rules (same logic)
        -----------------------------------------*/
        CASE
            WHEN LIBRARY_TITLE_FULL IS NULL OR COALESCE(TRIM(LIBRARY_TITLE_FULL), '') = '' THEN 1 ELSE 0
        END AS F_LTF_INCOMPLETE,

        CASE
            WHEN LIBRARY_TITLE_FULL IS NOT NULL
             AND (
                    UPPER(LIBRARY_TITLE_FULL) LIKE 'THE %'
                 OR UPPER(LIBRARY_TITLE_FULL) LIKE 'AN %'
                 OR UPPER(LIBRARY_TITLE_FULL) LIKE 'A %'
                 )
            THEN 1 ELSE 0
        END AS F_LTF_LEADING_ARTICLE,

        CASE
            WHEN LIBRARY_TITLE_FULL IS NOT NULL
             AND (
                    (
                      REGEXP_REPLACE(LIBRARY_TITLE_FULL, '[\u2018\u2019\u201C\u201D]', '')
                      != REGEXP_REPLACE(
                            REGEXP_REPLACE(LIBRARY_TITLE_FULL, '[\u2018\u2019\u201C\u201D]', ''),
                            '[^ -~]',
                            ''
                         )
                    )
                 OR REGEXP_LIKE(
                        LIBRARY_TITLE_FULL,
                        $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$
                    )
                 )
            THEN 1 ELSE 0
        END AS F_LTF_SPECIAL_CHAR

    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE
),
FINAL_COMPLETENESS_TABLE as (
SELECT
    NODE_IDENTIFIER,

    /* ✅ Always show the actual title fields */
    TITLE,
    LIBRARY_TITLE_SHORT,
    LIBRARY_TITLE_FULL,

    /* Optional: keep your "issue value columns" for export */
    CASE WHEN F_TITLE_INCOMPLETE = 1 THEN TITLE ELSE NULL END AS Incomplete_Titles,
    CASE WHEN F_TITLE_HAS_YEAR   = 1 THEN TITLE ELSE NULL END AS Titles_with_Release_Year,

    CASE WHEN F_LTS_INCOMPLETE       = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Incomplete_Library_Short_Titles,
    CASE WHEN F_LTS_LEADING_ARTICLE  = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Leading_Article_Library_Title_Short,
    CASE WHEN F_LTS_SPECIAL_CHAR     = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Special_Char_In_Library_short_Titles,
    CASE WHEN F_LTS_OVER_40          = 1 THEN LIBRARY_TITLE_SHORT ELSE NULL END AS Over_40_Char_limit_length,

    CASE WHEN F_LTF_INCOMPLETE      = 1 THEN LIBRARY_TITLE_FULL ELSE NULL END AS Incomplete_Library_Full_Titles,
    CASE WHEN F_LTF_LEADING_ARTICLE = 1 THEN LIBRARY_TITLE_FULL ELSE NULL END AS Leading_Article_Library_Title_Full,
    CASE WHEN F_LTF_SPECIAL_CHAR    = 1 THEN LIBRARY_TITLE_FULL ELSE NULL END AS Special_Char_In_Library_Full_Titles,

    /* ✅ Flag column (profile status) */
    CASE
        WHEN (F_TITLE_INCOMPLETE = 1 OR F_LTS_INCOMPLETE = 1 OR F_LTF_INCOMPLETE = 1)
            THEN 'INCOMPLETE'
        WHEN (
                F_TITLE_HAS_YEAR = 1
             OR F_LTS_LEADING_ARTICLE = 1 OR F_LTS_SPECIAL_CHAR = 1 OR F_LTS_OVER_40 = 1
             OR F_LTF_LEADING_ARTICLE = 1 OR F_LTF_SPECIAL_CHAR = 1
             )
            THEN 'AT_RISK'
        ELSE 'COMPLETE'
    END AS Profile_Status,

    /* ✅ Command column: list the issues triggered */
    ARRAY_TO_STRING(
        ARRAY_COMPACT(
            ARRAY_CONSTRUCT(
                IFF(F_TITLE_INCOMPLETE = 1, 'TITLE:Incomplete', NULL),
                IFF(F_TITLE_HAS_YEAR   = 1, 'TITLE:Release_Year', NULL),

                IFF(F_LTS_INCOMPLETE      = 1, 'LTS:Incomplete', NULL),
                IFF(F_LTS_LEADING_ARTICLE = 1, 'LTS:Leading_Article', NULL),
                IFF(F_LTS_SPECIAL_CHAR    = 1, 'LTS:Special_Char', NULL),
                IFF(F_LTS_OVER_40         = 1, 'LTS:Over_40', NULL),

                IFF(F_LTF_INCOMPLETE      = 1, 'LTF:Incomplete', NULL),
                IFF(F_LTF_LEADING_ARTICLE = 1, 'LTF:Leading_Article', NULL),
                IFF(F_LTF_SPECIAL_CHAR    = 1, 'LTF:Special_Char', NULL)
            )
        ),
        '; '
    ) AS Command_Issue

FROM rules)
SELECT 
NODE_IDENTIFIER,
TITLE,
LIBRARY_TITLE_SHORT,
LIBRARY_TITLE_FULL,
Profile_Status,
Command_Issue
FROM FINAL_COMPLETENESS_TABLE
WHERE Profile_Status <> 'COMPLETE';



WITH EPISODIC_FORMAT AS (
SELECT NODE_IDENTIFIER,
TITLE,
LIBRARY_TITLE_FULL,
LIBRARY_TITLE_SHORT,
CASE WHEN (UPPER(TITLE) NOT LIKE '%SEASON%') AND (UPPER(TITLE) LIKE '%EPISODE%' OR UPPER(TITLE) LIKE '%EP%')
          OR (UPPER(TITLE) LIKE '%SEASON%' AND UPPER(TITLE) NOT LIKE '%EPISODE #%')
     THEN 'Yes'
     WHEN (NOT REGEXP_LIKE(UPPER(LIBRARY_TITLE_FULL), 'S\\d')) AND (UPPER(LIBRARY_TITLE_FULL) LIKE '%EPISODE%' OR UPPER(LIBRARY_TITLE_FULL) LIKE '%EP%')
          OR (REGEXP_LIKE(UPPER(LIBRARY_TITLE_FULL), 'S\\d') AND UPPER(LIBRARY_TITLE_FULL) NOT LIKE '%EPISODE #%')
     THEN 'Yes'
     WHEN (NOT REGEXP_LIKE(UPPER(LIBRARY_TITLE_SHORT), 'S\\d')) AND (UPPER(LIBRARY_TITLE_SHORT) LIKE '%EPISODE%' OR UPPER(LIBRARY_TITLE_SHORT) LIKE '%EP%')
          OR (REGEXP_LIKE(UPPER(LIBRARY_TITLE_SHORT), 'S\\d') AND UPPER(LIBRARY_TITLE_SHORT) NOT LIKE '%EPISODE #%')
          OR (REGEXP_LIKE(UPPER(LIBRARY_TITLE_SHORT), 'S\\d') AND UPPER(LIBRARY_TITLE_SHORT) NOT LIKE 
'%EPI #%')
          OR (REGEXP_LIKE(UPPER(LIBRARY_TITLE_SHORT), 'S\\d') AND UPPER(LIBRARY_TITLE_SHORT) NOT LIKE 
'%EP #%')
     THEN 'Yes'
     ELSE 'No'
END AS ISSUES
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE
WHERE IP_TYPE IN ('Episode','Special','Short','Segment','Music','Publishing','Pilot','Game','')
)
SELECT *
FROM EPISODIC_FORMAT
WHERE ISSUES='Yes'
;


/*
================================================================================
                      PROFILE HEALTH FRAMEWORK - DOCUMENTATION
================================================================================

This document explains what this script does, why it is built the way it is, and
how to apply the same framework to any other dataset. It is written in plain
language with worked examples throughout. No code is reproduced here - the code
is above; this explains it.

--------------------------------------------------------------------------------
CONTENTS
--------------------------------------------------------------------------------
  1.  Purpose and core idea
  2.  The four inputs the framework needs
  3.  Layer 1 - The Applicability Matrix (the control plane)
  4.  Layer 2 - The Attribute Fact (wide to long)
  5.  Layer 3 - Weighted completeness scoring, with worked examples
  6.  Layer 4 - Hierarchy integrity and orphan detection, with worked examples
  7.  Layer 5 - The overall health verdict
  8.  Layer 6 - The five reports produced
  9.  The format hygiene module, with worked examples
 10.  The episodic naming module
 11.  Reading the output - a steward's guide
 12.  Known defects to be aware of
 13.  How to apply this framework to a new dataset
 14.  Calibration and operations
 15.  Glossary


--------------------------------------------------------------------------------
 1. PURPOSE AND CORE IDEA
--------------------------------------------------------------------------------

The framework answers one question for every record in a dataset:

    "Is this record fit to use, and if not, exactly what is wrong with it?"

Most data quality checks answer this by counting nulls. That approach fails as
soon as records are not all the same shape. In this dataset a Series, a Season
and an Episode are all rows in the same table, but they are governed by
different rules. A Series legitimately has no parent Season. An Episode
legitimately has no episode count. Counting nulls across a mixed table produces
a number that punishes records for fields they were never supposed to have.

The core idea of this framework is therefore:

    Completeness is measured only against the fields that matter FOR THAT
    RECORD'S TYPE, and each field carries a WEIGHT reflecting how much it
    matters.

Two consequences follow, and they are the whole point of the design:

  * A field that is not applicable to a type is excluded from BOTH the score
    earned and the score achievable. It cannot help and cannot hurt.

  * A missing primary key is not treated the same as a missing genre tag,
    because they do not carry the same weight.

The framework then adds two further dimensions - whether the record sits
correctly in the parent/child hierarchy, and whether its text fields obey
naming standards - and combines everything into a single verdict plus an
actionable list of defects.


--------------------------------------------------------------------------------
 2. THE FOUR INPUTS THE FRAMEWORK NEEDS
--------------------------------------------------------------------------------

  INPUT 1 - AN ENTITY TABLE
      One row per thing being governed, with a stable unique identifier.
      Here: the title table, identified by node identifier.

  INPUT 2 - A TYPE DISCRIMINATOR
      A column that buckets records into governance classes, because different
      classes are held to different standards.
      Here: IP type - Series, Season, Episode, and so on.

  INPUT 3 - A SET OF GOVERNED ATTRIBUTES
      The columns that actually matter. Not every column in the table - only
      those a steward would chase someone to fix.
      Here: seventeen attributes including the title fields, the various
      identifier numbers, release year, genre and episode counts.

  INPUT 4 - A HIERARCHY SOURCE (optional)
      Parent/child relationships between records.
      Here: the episodic title hierarchy view, linking Episode to Season to
      Series.

If a dataset has no natural type discriminator, the framework still works -
treat every record as a single type. It degenerates gracefully into a flat
weighted score. If a dataset has no hierarchy, layers 4 is simply skipped and
the verdict is driven by completeness alone.


--------------------------------------------------------------------------------
 3. LAYER 1 - THE APPLICABILITY MATRIX (THE CONTROL PLANE)
--------------------------------------------------------------------------------

This is the single most important part of the framework. It is a small lookup
table holding one row for every combination of record type and attribute that
is governed. Everything else in the script is generic machinery; all the
business judgement lives here.

Each row carries five pieces of information:

  TYPE           Which record type the rule applies to.
  ATTRIBUTE      Which column is being governed.
  APPLICABILITY  Mandatory or Optional. This is documentation for humans - it
                 does not enter the arithmetic.
  CRITICALITY    Critical, Medium or Low. This drives the human-readable defect
                 list, so a steward can triage. It does not enter the
                 arithmetic either.
  WEIGHT         An integer. This is the only field that affects the score.

An illustrative extract, in plain terms:

  For a SEASON record:
      Library title full ......... Mandatory, Critical, weight 10
      Library title short ........ Mandatory, Critical, weight  9
      IP type .................... Mandatory, Critical, weight 10
      PI UUID .................... Mandatory, Critical, weight 10
      MPM family number .......... Mandatory, Critical, weight  9
      MPM number ................. Mandatory, Critical, weight  8
      Originally aired as ........ Optional,  Medium,   weight  5
      Original release year ...... Optional,  Medium,   weight  5
      Number of episodes ......... Optional,  Low,      weight  4
      Meta ID .................... Optional,  Low,      weight  3
      Property ID ................ Optional,  Low,      weight  3
      Turner title ID ............ Optional,  Low,      weight  3
      Genre ...................... Optional,  Low,      weight  2
      Start year ................. Optional,  Low,      weight  1
      End year ................... Optional,  Low,      weight  1
                                                       ---------
      Total achievable for a Season:                        83


THE TWO PROPERTIES THAT MAKE THIS WORK

  PROPERTY A - ABSENCE IS MEANINGFUL.
      If a combination of type and attribute is NOT listed in the matrix, that
      attribute is not applicable to that type, and it is dropped from both
      sides of the calculation.

      Worked illustration. MPM family number is listed for Season with weight
      9, but it is NOT listed for Series at all. So:

          A Season with a blank MPM family number loses 9 points out of 83.
          A Series with a blank MPM family number loses nothing whatsoever,
          because for a Series that field was never part of the deal.

      This is what "type-aware" means in practice, and it is the behaviour that
      a simple null count cannot reproduce.

  PROPERTY B - WEIGHTS ARE RELATIVE, NOT ABSOLUTE.
      The score divides by the sum of that type's own weights. So only the
      ratios within a type matter. Doubling every Season weight from
      (10,9,10,...) to (20,18,20,...) would change no score at all. This means
      you can tune one field's importance without having to rebalance the rest.


A DESIGN CHOICE WORTH EXPLAINING

  Note that for the UNKNOWN record type, IP type is weighted 2 and marked
  Optional and Low - whereas for every real type it is weighted 10 and marked
  Mandatory and Critical.

  This is deliberate. A record lands in the UNKNOWN bucket precisely because its
  IP type is missing or unrecognised. Charging it the full 10-point penalty
  would double-count the same defect: once by putting it in the UNKNOWN bucket,
  and again by docking its score. The low weight acknowledges the problem
  without letting it swamp everything else the record does have.


WHERE THE MATRIX LIVES TODAY, AND WHERE IT SHOULD LIVE

  In this script the matrix is written inline as a literal list of values,
  and that same list is repeated in full inside each of the five reports.
  That means a single weight change requires five identical edits, and the
  five copies can silently drift apart.

  For any new deployment, make the matrix a real table. Stewards can then
  govern data quality by updating rows, with no SQL change and no deployment.
  This is the difference between a script and a framework.


--------------------------------------------------------------------------------
 4. LAYER 2 - THE ATTRIBUTE FACT (WIDE TO LONG)
--------------------------------------------------------------------------------

The source table is wide: one column per attribute. The matrix is long: one row
per attribute. To compare them, the framework reshapes the source table from
wide to long, so that every governed column becomes a row.

Conceptually, one record goes from this:

    ID     TITLE        GENRE     META_ID    PI_UUID
    T-100  Batman       Action    (blank)    a1b2c3

to this:

    ID     ATTRIBUTE    VALUE     PRESENT?
    T-100  TITLE        Batman        1
    T-100  GENRE        Action        1
    T-100  META_ID      (blank)       0
    T-100  PI_UUID      a1b2c3        1

WHY BOTHER

  Because it converts "score seventeen different columns" into "join one table
  against the matrix". Adding an eighteenth governed attribute then becomes a
  matter of inserting a matrix row and adding one line to the reshape - not
  rewriting the scoring logic. The scoring, the banding and the defect list all
  stay untouched.

  The cost is that the reshape reads the source table once per attribute. On
  large tables this is the most expensive part of the pipeline, and it is worth
  replacing with a single-pass reshape (see section 13).

THE PRESENCE TEST, AND ITS LIMITATION

  A value is currently counted as present if it is not null. Note carefully
  what this does NOT catch: an empty string, a string of spaces, or a sentinel
  such as "N/A" or "UNKNOWN" all count as PRESENT and earn full weight.

  So a record whose library title short is a single space character scores
  exactly as well on that field as one with a real title. If the source has
  blank-string or sentinel conventions, the presence test must be tightened,
  or the scores will be optimistic.

THE TYPE NORMALISATION STEP

  Before joining to the matrix, the raw IP type is normalised: it is
  upper-cased, and any value outside a known list - or a null - is mapped to
  UNKNOWN. This guarantees every record matches exactly one type in the matrix
  and none fall through the join into a null score.

  Be aware that this script performs that normalisation TWICE, against two
  different lists - a long list during scoring and a shorter list during
  reporting. See section 12, defect 5.


--------------------------------------------------------------------------------
 5. LAYER 3 - WEIGHTED COMPLETENESS SCORING, WITH WORKED EXAMPLES
--------------------------------------------------------------------------------

Once the long attribute list is joined to the matrix, each record's score is:

    Completeness percent  =  (weight earned  /  weight achievable)  x  100

  WEIGHT EARNED
      Add up the weights of the applicable attributes that ARE populated.

  WEIGHT ACHIEVABLE
      Add up the weights of ALL applicable attributes for that record's type -
      populated or not. This is the type's total from the matrix.

Attributes not in the matrix for that type appear in neither sum.


WORKED EXAMPLE A - A SEASON RECORD

  Record S-4471, type Season. Achievable total for a Season is 83.

  Populated fields and the weight each earns:

      Library title full ............. 10
      Library title short ............  9
      IP type ........................ 10
      PI UUID ........................ 10
      MPM family number ..............  9
      MPM number .....................  8
      Original release year ..........  5
      Genre ..........................  2
                                     ----
      Weight earned ..................  63

  Blank fields and the weight each forfeits:

      Originally aired as ............  5
      Number of episodes .............  4
      Meta ID ........................  3
      Property ID ....................  3
      Turner title ID ................  3
      Start year .....................  1
      End year .......................  1
                                     ----
      Weight forfeited ...............  20

  Check: 63 earned + 20 forfeited = 83 achievable. Correct.

  Score:  63 / 83  =  0.759  ->  76 percent

  Interpretation: this record has every single Critical field populated. What
  it is missing is seven low and medium value descriptive fields. It scores 76
  and lands in the middle band - it is usable, but incomplete. A steward
  looking at this should note that no urgent action is needed.


WORKED EXAMPLE B - THE SAME GAPS ON A DIFFERENT TYPE

  Now consider record T-9002 with an identical pattern of blanks, but typed as
  Series instead of Season. A Series achievable total is 66, and the Series
  matrix does not include MPM family number, property ID, or originally aired
  as at all.

  Populated:  library title full 10, library title short 9, IP type 10,
              PI UUID 10, MPM number 8, original release year 5, genre 2
              = 54 earned

  Blank:      number of episodes 4, meta ID 3, turner title ID 3,
              start year 1, end year 1
              = 12 forfeited

  Check: 54 + 12 = 66. Correct.

  Score:  54 / 66  =  0.818  ->  82 percent

  THE POINT OF THIS COMPARISON. Both records have the same real-world
  populated fields and the same real-world blanks. Yet the Season scores 76
  and the Series scores 82. The Series scores higher because two of the fields
  the Season was penalised for - MPM family number and property ID - are not
  part of the Series contract, so their absence is simply not a defect.

  A naive null count would have scored these two records identically and
  would have been wrong in both directions.


WORKED EXAMPLE C - A CRITICAL FAILURE

  Record E-8813, type Episode. Achievable total 76.

  This record has a good spread of descriptive fields but its PI UUID is
  blank - the primary cross-system identifier.

  Populated:  library title full 10, library title short 9, IP type 10,
              MPM number 8, MPM product number 8, original release year 5,
              originally aired as 5, genre 2, meta ID 3, property ID 3,
              turner title ID 3
              = 66 earned

  Blank:      PI UUID 10
              = 10 forfeited

  Score:  66 / 76  =  0.868  ->  87 percent

  NOTE THE TRAP. This record scores 87, which lands in the healthy-looking
  middle band, yet it is missing the one identifier that downstream systems
  join on. It is arguably unusable.

  This is a real limitation of any single weighted score: one severe defect
  can be diluted by many minor successes. It is exactly why the framework does
  NOT rely on the score alone, and why it emits the criticality-tagged defect
  list described in section 11. The score tells you roughly how complete a
  record is; the defect list tells you whether the gaps are the ones that
  matter.

  If your domain cannot tolerate this dilution, add a hard rule to the verdict:
  any blank Critical attribute forces the record to Critical regardless of
  score.


THE BANDING

  Scores are then bucketed for reporting:

      Below 70 ............ poor
      70 to 90 inclusive .. middling
      Above 90 ............ good

  These cutoffs are a domain judgement, not a universal truth. Calibrate them
  against your own distribution - see section 14.


A MAINTENANCE HAZARD IN THE CURRENT CODE

  The achievable totals - 66 for Series, 83 for Season, 76 for Episode, 64 for
  Unknown - are written into the script as fixed divisors. They are correct as
  of today; each one does equal the sum of that type's weights.

  But they are not derived from the matrix, they are copied from it by hand. The
  moment anyone edits a weight or adds an attribute, the divisor no longer
  matches the matrix, and every score for that type becomes quietly wrong. No
  error is raised. Scores above 100 percent, or a sudden unexplained shift in
  the distribution, are the symptoms to watch for.

  The fix is to compute each type's achievable total from the matrix itself so
  the two can never disagree. This is the highest-value change to make when
  reusing this framework.


--------------------------------------------------------------------------------
 6. LAYER 4 - HIERARCHY INTEGRITY AND ORPHAN DETECTION, WITH EXAMPLES
--------------------------------------------------------------------------------

Completeness says whether a record describes itself properly. It says nothing
about whether the record is correctly connected to the rest of the data. A
perfectly complete Episode that hangs off a Season which does not exist is
still broken.

Here the structure is Series contains Season contains Episode, and each child
points at its parent using a business key rather than an internal ID.

The framework establishes structural validity in four steps.

  STEP 1 - BACKFILL MISSING PARENT KEYS
      The hierarchy source is not always populated. Where a parent key is
      missing there, the framework falls back to the equivalent field on the
      record itself. Only if both are blank is the parent treated as undeclared.
      This prevents records being condemned as orphans purely because one
      feed was incomplete.

  STEP 2 - RESOLVE BUSINESS KEYS TO REAL RECORDS
      A child declares a parent by business key. The framework builds a lookup
      from parent business key to parent record identifier, and joins it back.

      Business keys are not guaranteed unique in the source, so the lookup
      deliberately keeps only one row per key. This makes the join safe - it
      cannot multiply rows and inflate counts - but it does mean genuine
      duplicate parents are silently collapsed rather than reported. If
      duplicate parent keys matter in your domain, they need their own check.

      The crucial output of this step: if the declared key resolves to nothing,
      the parent does not exist.

  STEP 3 - CLASSIFY
      Two flags are produced.

      ORPHAN STATUS answers "does this record have a place to hang?"
          NO   - it is itself a parent of something, or it declares a parent
                 key that resolves to a real record.
          YES  - it declares no usable parent and nothing points to it. It is
                 floating free.

      HIERARCHY STATUS answers "is its position in the tree coherent?"
          VALID     - something references it as a parent, or its own declared
                      parent genuinely exists.
          NOT VALID - it claims a position the data does not support.

      NOT APPLICABLE is a third possibility, and it needs care. It arises when
      a record does not appear in the hierarchy source at all. Note that the
      framework treats this as a DEFECT, not as a neutral "not relevant".
      The reasoning: for a type that belongs in a hierarchy, being entirely
      absent from the hierarchy feed is itself a problem worth surfacing.

  STEP 4 - COUNT FAN-OUT
      A count of how many children each record has, summed across the levels
      and adjusted to remove the record's own self-match introduced by the
      join. This is informational - it identifies which records are structurally
      load-bearing, so a defect on a Series with 200 descendants can be
      prioritised over one with none.


WORKED EXAMPLES

  CASE 1 - A HEALTHY CHILD
      Episode E-1001 declares Season key M-500. A Season with MPM number M-500
      exists in the data. The key resolves.
          Orphan status .... NO
          Hierarchy status . VALID
      Structurally sound.

  CASE 2 - A BROKEN REFERENCE
      Episode E-1002 declares Season key M-999. No Season with that number
      exists anywhere. The key resolves to nothing.
          Orphan status .... YES
          Hierarchy status . NOT VALID
      This is the classic dangling reference. The record may be 100 percent
      complete and still be unusable, because anything that tries to roll it
      up to a Season will lose it. The verdict will be Critical.

  CASE 3 - A LEGITIMATE TOP-OF-TREE RECORD
      Series S-77 declares no parent - correctly, since a Series is the top of
      the tree. But three Seasons declare S-77 as their parent.
          Fan-out .......... 3
          Orphan status .... NO   (because it IS a parent)
          Hierarchy status . VALID
      Note the framework does not penalise a Series for having no parent. Being
      referenced as a parent is itself sufficient proof of a valid position.
      This is why the orphan test checks both directions.

  CASE 4 - MISSING FROM THE HIERARCHY FEED
      Episode E-1003 exists in the entity table but appears nowhere in the
      hierarchy source, on either side.
          Orphan status .... NOT APPLICABLE
          Hierarchy status . NOT APPLICABLE
      Treated as Critical. In practice a large volume of this outcome usually
      indicates a feed or join problem rather than genuinely bad records - see
      section 14.

  CASE 5 - RESCUED BY BACKFILL
      Episode E-1004 has a blank Season key in the hierarchy source, but its own
      MPM product number field carries M-500. Step 1 backfills from the record,
      the key then resolves in step 2.
          Orphan status .... NO
          Hierarchy status . VALID
      Without the backfill this record would have been wrongly reported as an
      orphan.


--------------------------------------------------------------------------------
 7. LAYER 5 - THE OVERALL HEALTH VERDICT
--------------------------------------------------------------------------------

The three dimensions collapse into one verdict, evaluated in strict order. The
first condition that matches decides the outcome; later conditions are not
considered.

      Order  Condition                              Verdict
      -----  ------------------------------------   ---------
        1    Hierarchy status is NOT VALID          Critical
        2    Hierarchy status is NOT APPLICABLE     Critical
        3    Orphan status is YES                   Critical
        4    Completeness below 70                  Critical
        5    Completeness between 70 and 90         High Risk
        6    Everything else                        Healthy

WHY STRUCTURE IS TESTED BEFORE COMPLETENESS

  The ordering encodes a priority judgement: a structurally broken record is
  unusable no matter how well described it is, whereas an incompletely
  described record that is correctly connected is at least partially usable.

  Concretely, a record scoring 98 percent completeness but flagged as an orphan
  returns Critical. It never reaches the completeness tests, because condition
  3 matched first. That is intended. The record's beautiful metadata is
  worthless if nothing can find it.

WHAT THE VERDICT DOES AND DOES NOT TELL YOU

  It tells you: how urgently to act.
  It does not tell you: what to fix. That is the defect list in section 11.

  Also note the dilution effect demonstrated in worked example C - a record can
  return High Risk or even Healthy while missing a Critical identifier. Treat
  the verdict as a triage signal, not as proof of fitness.


--------------------------------------------------------------------------------
 8. LAYER 6 - THE FIVE REPORTS PRODUCED
--------------------------------------------------------------------------------

Everything above is computed per record. The script then presents it five ways.
All five rest on the identical core calculation.

  REPORT 1 - ATTRIBUTE COMPLETENESS MATRIX
      Grain: one row per record type, one column per attribute.
      Shows the percentage of records of that type having each attribute
      populated.
      Answers: "Which fields are weakest across the whole estate?"
      Use it to decide where a bulk remediation campaign would pay off. If
      genre is 12 percent populated for Episodes, that is a project. If it is
      97 percent, chase the stragglers individually.

  REPORT 2 - COMPLETENESS BANDING BY TYPE
      Grain: one row per record type.
      Three counts: records below 70, between 70 and 90, and above 90.
      Answers: "How well described is each type of record?"

  REPORT 3 - HIERARCHY BANDING BY TYPE
      Grain: one row per record type.
      Two counts: valid, and not valid (which includes orphans).
      Answers: "How much of my structure is broken, and where?"

  REPORT 4 - OVERALL HEALTH BANDING BY TYPE
      Grain: one row per record type.
      Counts by verdict.
      Answers: "What is my headline position?" This is the executive view.
      IMPORTANT: this report is currently faulty - see section 12, defect 2. It
      undercounts, and should not be circulated until fixed.

  REPORT 5 - DAILY DELTA
      Grain: one row per record, filtered to those whose last-updated date
      equals the maximum last-updated date in the table.
      Also carries who last updated the record.
      Answers: "What did we create or change today, and was it any good?"
      Use it to catch a bad load on the day it lands rather than a month later,
      and to route defects to the person who introduced them.

      Be aware of what this report cannot do. Because it filters to the latest
      date rather than comparing against history, it answers "what changed
      today" but NOT "are we getting better over time". Trend reporting needs
      daily snapshots to be retained - see section 14.


--------------------------------------------------------------------------------
 9. THE FORMAT HYGIENE MODULE, WITH WORKED EXAMPLES
--------------------------------------------------------------------------------

This is a separate engine with a separate purpose. Completeness asks whether a
field is filled in. Hygiene asks whether what is in it is well-formed. A title
can be fully populated and still be wrong.

It follows the same three-part shape: raise a flag per rule, classify into a
status, then explain in a readable string.

THE RULES IMPLEMENTED

  EMPTY OR WHITESPACE
      The field is null, or contains only spaces. Note this rule is stricter
      than the presence test used in the completeness scoring, which is why a
      record can be 100 percent complete and still flagged INCOMPLETE here.

  EMBEDDED RELEASE YEAR
      A four-digit year in the 1900s or 2000s appears inside the title text.
      Titles are supposed to carry the name; the year belongs in its own field.
      Duplicating it causes mismatches downstream.
      The pattern is careful to require non-digits either side, so that a long
      identifier such as 123419995678 does not falsely trip the rule.

  LEADING ARTICLE
      The title begins with "The ", "An " or "A ". These break alphabetical
      sorting - every title in the catalogue files under T - so the house style
      requires them moved or dropped.

  NON-ASCII CHARACTERS
      Any character outside the printable ASCII range. Accented letters and
      typographic dashes tend to break older downstream systems.
      One deliberate exception: curly quotation marks and apostrophes are
      stripped out BEFORE the test, so they are tolerated. They are common,
      harmless, and not worth flagging.

  DISALLOWED PUNCTUATION
      Any character outside an approved set of letters, digits, spaces, and a
      specific short list of permitted punctuation.

  LENGTH CAP
      Short titles longer than 40 characters, because a downstream display or
      contract imposes that limit.


THE TWO OUTPUT COLUMNS

  PROFILE STATUS - a single verdict, in priority order:
      INCOMPLETE  if any emptiness rule fired. This wins over everything.
      AT RISK     if the field is populated but any hygiene rule fired.
      COMPLETE    if nothing fired.

  ISSUE LIST - a semicolon-separated list of short codes naming every rule that
  fired, so the record explains itself.


WORKED EXAMPLES

  Value: "Batman Begins (2005)"
      Contains 2005, surrounded by non-digits. The year rule fires.
      Status: AT RISK        Issues: TITLE:Release_Year
      Remedy: remove the year from the title; it belongs in the release year
      field.

  Value: "The Sopranos"
      Begins with "The ". The leading article rule fires.
      Status: AT RISK        Issues: LTS:Leading_Article
      Remedy: restyle as "Sopranos, The" or drop the article per house style.

  Value: "Cafe Society" written with an accented e
      The accented character is outside printable ASCII.
      Status: AT RISK        Issues: LTS:Special_Char
      Remedy: transliterate to plain ASCII, or grant an exception if all
      downstream consumers handle Unicode.

  Value: "It's Always Sunny" written with a curly apostrophe
      The curly apostrophe is stripped before the ASCII test, so nothing fires.
      Status: COMPLETE       Issues: (none)
      This is the intended tolerance, not an oversight.

  Value: a 45-character short title
      Exceeds the 40-character cap.
      Status: AT RISK        Issues: LTS:Over_40

  Value: null
      Status: INCOMPLETE     Issues: LTF:Incomplete

  Value: "The Cafe" with an accented e
      Two rules fire at once - leading article and non-ASCII.
      Status: AT RISK        Issues: LTS:Leading_Article; LTS:Special_Char
      This shows how the issue list accumulates. A record with five problems
      names all five, so it can be fixed in one pass rather than five.

  Combination case: a record whose full title is blank AND whose short title
  begins with "A " and is 50 characters long.
      Three rules fire, one of them an emptiness rule.
      Status: INCOMPLETE     Issues: LTF:Incomplete; LTS:Leading_Article;
                                     LTS:Over_40
      Note the status is INCOMPLETE, not AT RISK, because emptiness takes
      priority - but the issue list still reports all three, so nothing is
      hidden by the priority rule.


TWO BUGS IN THIS MODULE

  The leading-article rules and one of the emptiness rules are both defective
  as written. See section 12, defects 3 and 4. Both cause over-reporting or
  mis-reporting on the title fields, so counts from this module should be
  treated as indicative until corrected.


--------------------------------------------------------------------------------
10. THE EPISODIC NAMING MODULE
--------------------------------------------------------------------------------

The last section of the script checks a domain-specific naming convention on
episodic records - Episode, Special, Short, Segment and similar types.

The convention being enforced is that when a title identifies a season, the
episode must be numbered in a specific form using a hash symbol. So a title of
the shape "S01 Episode #5" is acceptable; "S01 Episode 5" is not, because the
number is not marked, and downstream parsers that split on the hash will fail
to extract the episode number.

The check inspects all three title variants and flags a record if any of them
violates the convention. Only violating records are returned, since a report
that lists compliant records is not actionable.

Worked illustration:

      "Friends S01 Episode #5"  ->  compliant. Season marker present, episode
                                    number properly delimited.
      "Friends S01 Episode 5"   ->  flagged. Season marker present but no hash
                                    delimiter before the number.
      "Friends Episode 5"       ->  flagged. Mentions an episode but carries no
                                    season marker at all, so it cannot be
                                    placed within a season.

A caution on this module: the conditions mix AND and OR across several lines
without full parenthesisation, and the abbreviation match is loose enough that
any title containing the letter pair "ep" anywhere - inside a word such as
"deep" or "epic" - can satisfy part of a condition. Expect false positives.
Review a sample of the output before acting on the volume.


--------------------------------------------------------------------------------
11. READING THE OUTPUT - A STEWARD'S GUIDE
--------------------------------------------------------------------------------

Alongside the numeric score, the framework produces the two columns that make
it actionable. Each governed attribute is rendered as a small labelled fragment
carrying its name and its criticality, and these are concatenated into two
lists per record: one of attributes present, one of attributes missing.

A missing list might read, in effect:

      [COLUMN: PI_UUID, CRITICALITY: Critical] |
      [COLUMN: GENRE, CRITICALITY: Low] |
      [COLUMN: END_YEAR, CRITICALITY: Low]

HOW TO USE THIS

  This is the part a steward actually works from. The score of 87 in worked
  example C tells you very little. The missing list telling you that PI UUID -
  Critical - is absent tells you exactly what to do, and that it is urgent.

  Read the two columns together with the verdict:

      Verdict Critical, and the missing list contains Critical entries.
          Genuine urgent data gap. Fix the named fields.

      Verdict Critical, but the missing list contains only Low entries.
          The verdict is being driven by the hierarchy or orphan flags, not by
          completeness. Do not chase fields - investigate the parent linkage.

      Verdict High Risk or Healthy, but the missing list contains a Critical
      entry.
          This is the dilution trap. The score is reassuring and wrong. These
          records deserve priority despite their band, and are the strongest
          argument for adding a hard Critical-field override to the verdict.

      Verdict Healthy and no Critical entries missing.
          Leave it alone.

THE TWO COUNT COLUMNS

  Two convenience counts accompany the lists - the number of attributes present
  and the number missing. Note that these are currently derived by counting
  separators in the concatenated string rather than by counting the underlying
  rows. For a record with nothing missing, the string is empty but the count
  still returns one. Treat both counts as unreliable and read the lists
  themselves. See section 12, defect 6.


--------------------------------------------------------------------------------
12. KNOWN DEFECTS TO BE AWARE OF
--------------------------------------------------------------------------------

These are real faults in the current script, listed so that nobody
misinterprets the output or carries the faults into a reuse.

  DEFECT 1 - HARDCODED DIVISORS (correctness risk, high)
      The achievable totals per type are hand-copied constants rather than
      being derived from the matrix. Correct today, silently wrong after any
      weight edit. Every score for the affected type would shift with no error
      raised.

  DEFECT 2 - THE OVERALL HEALTH REPORT UNDERCOUNTS (correctness, high)
      The verdict logic emits three labels: Critical, High Risk, Healthy. The
      overall health report counts three labels: Critical, Normal, Healthy.
      The middle label does not match.
      Consequence: the Normal column is always zero, and every High Risk record
      is dropped from the report entirely. The totals do not reconcile to the
      record count. This is the executive-facing report, so the impact is
      disproportionate. Do not circulate it until the labels are aligned.

  DEFECT 3 - OPERATOR PRECEDENCE IN THE LEADING ARTICLE RULES (correctness)
      The condition is written as a null guard AND the first pattern, then OR
      the second pattern, OR the third, without parentheses. Because AND binds
      more tightly than OR, the guard protects only the first pattern. The
      second and third are evaluated unguarded.
      Consequence: over-reporting on the leading article rules.

  DEFECT 4 - WRONG COLUMN IN THE FULL TITLE EMPTINESS CHECK (correctness)
      The incomplete-full-title rule tests whether the full title is null OR
      the SHORT title is blank. The second half reads the wrong field.
      Consequence: records with a populated full title but a blank short title
      are reported as having an incomplete full title.

  DEFECT 5 - THE TYPE LIST IS DEFINED TWICE AND THE TWO DIVERGE (correctness)
      Type normalisation happens once during scoring against a long list of
      values, and again during reporting against a much shorter list. A type
      present in the first list but absent from the second is scored as itself
      but reported as UNKNOWN.
      Consequence: a record can be classified one way in its score and another
      way in the report it appears in, so per-type figures do not reconcile.
      Both places must share one mapping.

  DEFECT 6 - THE PRESENT AND MISSING COUNTS ARE UNRELIABLE (correctness, minor)
      Both are derived by splitting the concatenated label string on its
      separator and taking its size, rather than by counting rows. An empty
      string still splits to one element, so a record with zero missing
      attributes reports one missing. Counts should be taken in the aggregation
      step instead.

  DEFECT 7 - THE CORE PIPELINE IS DUPLICATED FIVE TIMES (maintainability, high)
      Roughly nine hundred lines - the matrix, the reshape, the scoring and the
      hierarchy logic - are repeated verbatim once per report.
      Consequence: every rule change needs five synchronised edits; a missed
      one causes reports to disagree with each other with no error; and the
      source table is scanned five times over, multiplying cost. This is the
      main structural problem with the script.

  DEFECT 8 - A CTE REDEFINES ITS OWN NAME (maintainability)
      The hierarchy integrity step is defined, then a second step of the same
      name selects from the first. This resolves, but it is fragile and makes
      the logic very hard to follow. The name is also misspelled consistently
      throughout, which makes searching harder.

  DEFECT 9 - CASING INCONSISTENCY BETWEEN MATRIX AND FACT (maintainability)
      The matrix stores type names in mixed case while the fact layer
      normalises to upper case, so the join has to upper-case one side on every
      execution. Storing the matrix pre-normalised removes both the per-row
      work and a class of silent join misses.

  DEFECT 10 - THE PRESENCE TEST IS TOO PERMISSIVE (correctness, domain
  dependent)
      Empty strings, whitespace and sentinel values all count as populated and
      earn full weight, so scores may be optimistic. Whether this matters
      depends entirely on the source's conventions.


--------------------------------------------------------------------------------
13. HOW TO APPLY THIS FRAMEWORK TO A NEW DATASET
--------------------------------------------------------------------------------

Nothing in the scoring, banding, verdict or defect-list logic is specific to
titles. Only three things are domain-specific: the type mapping, the
applicability matrix, and the hierarchy join keys. Porting means repopulating
those, not rewriting the logic.

  STEP 1 - IDENTIFY YOUR FOUR INPUTS
      Entity table with a stable identifier; type discriminator; the set of
      attributes worth governing; and a hierarchy source if one exists.

      On choosing governed attributes: include a field only if someone would
      genuinely chase a colleague to populate it. Governing everything
      produces a score that never moves and that nobody trusts.

      If there is no type discriminator, use a single constant type. The
      framework reduces to a flat weighted score and everything else still
      works.

  STEP 2 - BUILD TWO CONTROL TABLES
      A type mapping table - raw source value to governance type, with anything
      unmapped or null falling to a catch-all bucket. Use this in ONE place so
      defect 5 cannot recur.

      An applicability matrix table with the five fields from section 3, keyed
      on type plus attribute so duplicates are impossible.

      Weighting guidance, which is where most of the thinking goes:
          Identifiers and join keys that other systems depend on ....... 8 to 10
          Fields with a regulatory or contractual obligation ........... 5 to 9
          Descriptive and nice-to-have fields ......................... 1 to 4
      Remember only the ratios within a type matter, so do not agonise over
      absolute numbers. Do set criticality honestly, because that is what
      stewards triage on.

  STEP 3 - RESHAPE WIDE TO LONG
      Prefer a single-pass reshape that turns each row into its set of
      attribute values in one scan, over the repeated-union approach used here.
      The output is identical; the cost is one table scan instead of one per
      attribute. On a large table this is the difference between minutes and
      hours.

      Decide your presence test explicitly at this point, in light of
      defect 10.

  STEP 4 - MATERIALISE THE CORE, NOT THE REPORTS
      Build ONE table at record grain holding: identifier, governance type,
      completeness score, hierarchy status, orphan status, fan-out count,
      verdict, the present and missing lists, honest present and missing
      counts, the source's last-updated timestamp and user, and the timestamp
      of the quality run itself.

      Every report then becomes a short grouping over that one table. This
      single decision resolves defect 7, removes the possibility of reports
      disagreeing, and cuts compute roughly fivefold.

  STEP 5 - DERIVE THE DIVISORS
      Compute each type's achievable total from the matrix so it cannot drift.
      Resolves defect 1.

  STEP 6 - PORT THE HIERARCHY LOGIC IF RELEVANT
      Substitute your own parent business keys and your own backfill fallbacks.
      Keep the two-directional orphan test - referenced as a parent, or
      declaring a resolvable parent - because that is what stops top-of-tree
      records being wrongly condemned.
      Decide deliberately whether absence from the hierarchy source should be
      a defect in your domain, as it is here, or genuinely neutral.

  STEP 7 - REVIEW THE VERDICT ORDERING
      The ordering in section 7 encodes the judgement that structure outranks
      description. If your domain disagrees, reorder it. Consider adding the
      hard override discussed in worked example C, so that any blank Critical
      attribute forces a Critical verdict regardless of score.


--------------------------------------------------------------------------------
14. CALIBRATION AND OPERATIONS
--------------------------------------------------------------------------------

CALIBRATE BEFORE PUBLISHING

  Run the framework once and look at the distribution of verdicts before
  showing anyone the numbers. The first run is almost never right, and the
  shape of the distribution tells you what is wrong.

  If nearly everything is Critical.
      Do not conclude the data is uniformly bad. Check the count of NOT
      APPLICABLE hierarchy outcomes first. A large number almost always means
      parent keys are failing to resolve for a systematic reason - a feed not
      loaded, a key format mismatch, a stale snapshot - rather than that every
      record is genuinely broken. Fix the resolution before believing the
      verdict.

  If nearly everything is Healthy.
      The weights are probably concentrated on fields that are always
      populated, such as system-generated identifiers. The score cannot
      discriminate. Shift weight toward the fields that actually vary and that
      stewards care about.

  If the distribution is bimodal with nothing in the middle.
      Usually one very heavy attribute is dominating the score. Consider
      flattening the weights.

  The goal is a distribution that separates records into groups a team can act
  on differently. Re-check it after every matrix change, because a weight edit
  can move thousands of records across a band boundary.

OPERATE IT

  Schedule the core refresh to run after the source load completes, not on a
  fixed clock, or the daily delta report will read a half-loaded table.

  Retain daily snapshots of the core table. Without history you can report
  today's state but you cannot show whether quality is improving, and
  improvement is the only thing anyone will eventually ask about.

  Route the missing list to the person named in the last-updated field. A
  defect report that reaches the individual who introduced the defect gets
  fixed; one that reaches a central mailbox does not.

  Alert on distribution shifts rather than on absolute thresholds. A jump in
  Critical count between two runs is a signal worth waking someone for; a
  steady Critical count is a backlog to work through, not an incident.


--------------------------------------------------------------------------------
15. GLOSSARY
--------------------------------------------------------------------------------

  APPLICABILITY MATRIX   The control table declaring which attributes are
                         governed for which record type, and how heavily.

  APPLICABLE             An attribute is applicable to a type if the pair
                         appears in the matrix. Non-applicable attributes are
                         excluded from both the score earned and the score
                         achievable.

  WEIGHT EARNED          Sum of weights of applicable attributes that are
                         populated on a given record.

  WEIGHT ACHIEVABLE      Sum of weights of all applicable attributes for that
                         record's type. The divisor.

  COMPLETENESS           Weight earned divided by weight achievable, as a
                         percentage.

  CRITICALITY            The human triage label on an attribute. Drives the
                         defect list; does not affect the score.

  ORPHAN                 A record that neither is a parent nor declares a
                         parent that resolves to a real record.

  DANGLING REFERENCE     A record declaring a parent key that resolves to
                         nothing.

  FAN-OUT                How many children a record has. Used to prioritise.

  NOT APPLICABLE         A record absent from the hierarchy source. Treated
                         here as a defect, not as neutral.

  VERDICT                The single overall health label, decided by the
                         first matching condition in the ordered test.

  DILUTION               The failure mode where many minor successes mask one
                         severe defect in a single weighted score. Countered
                         by reading the criticality-tagged defect list.

  DEFECT LIST            The two concatenated columns naming which attributes
                         are present and which are missing, each tagged with
                         its criticality. The actionable output.

================================================================================
                              END OF DOCUMENTATION
================================================================================
*/