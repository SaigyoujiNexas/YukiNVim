SELECT
    dt,
    ai,
    temp
FROM
    test
WHERE
    `dt`IN(
        '2021341',
        '23413'
    )
    AND pt = 'Android'
GROUP BY
    dt
