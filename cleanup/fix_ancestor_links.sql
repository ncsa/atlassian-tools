UPDATE
  issuelink, issuelinktype, issuelinktype linktype_old, issuelinktype linktype_new SET
  issuelink.linktype = linktype_new.id
WHERE
  issuelink.linktype = linktype_old.id AND
  linktype_old.linkname = 'Ancestor' AND
  linktype_new.linkname = 'Parent-Child Link';


DELETE FROM issuelinktype
WHERE linkname IN ('Ancestor');
