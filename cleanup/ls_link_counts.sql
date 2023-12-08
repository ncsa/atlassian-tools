SELECT
    COUNT(link.id) AS issue_count
  , ltype.linkname
  , MAX(ltype.id) AS linktypeid
  , MAX(ltype.inward) AS inward
  , MAX(ltype.outward) AS outward
  , MAX(ltype.pstyle) AS pstyle
FROM issuelinktype ltype
LEFT OUTER JOIN issuelink link ON
  ltype.id = link.linktype
GROUP BY
  ltype.linkname;
