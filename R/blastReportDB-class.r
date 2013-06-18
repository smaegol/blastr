#' @include blastReport-class.r
#' @importClassesFrom RSQLite SQLiteConnection
#' @importClassesFrom RSQLite SQLiteObject
#' @importClassesFrom RSQLite dbObjectId
#' @importClassesFrom DBI DBIConnection
#' @importClassesFrom DBI DBIObject
#' @importFrom IRanges IRanges
#' @importFrom IRanges IRangesList
#' @importFrom IRanges reduce
#' @importFrom IRanges width
#' @importFrom IRanges unlist
NULL

# blastReportDB-class ----------------------------------------------------


#' blastReportDB class
#' 
#' blastReportDB is an S4 class that represents a connection to an SQLite
#' database holding blast records organised in three tables:
#' query, hit, and hsp
#' 
#' @name blastReportDB-class
#' @rdname blastReportDB-class
#' @exportClass blastReportDB
setClass('blastReportDB', contains='SQLiteConnection')


setValidity('blastReportDB', function (object) {
  if (!all(c("hit","hsp","query") %in% dbListTables(object)))
    return("Table missing from 'blastReportDB'")
  if (!all(c("query_id","query_def","query_len") %in% dbListFields(object, "query")))
    return("Field missing from table 'query'")
  if (!all(c("query_id","hit_id","hit_num","gene_id","accession",
             "definition","length") %in% dbListFields(object, "hit")))
    return("Field missing from table 'query'")
  if (!all(c("query_id","hit_id","hsp_id","hsp_num","bit_score",
             "score","evalue","query_from","query_to","hit_from",
             "hit_to","query_frame","hit_frame","identity","positive",
             "gaps","align_len","qseq","hseq","midline") 
           %in% dbListFields(object, "hsp")))   
    return("Field missing from table 'query'")
  TRUE
})


# constructor, blastReportDB-class ####
blastReportDB <- function(dbPath = "~/local/workspace/sqlite3/sample64.db") {
  assert_that(is.readable(dbPath))
  con <- db_connect(dbPath)
  new("blastReportDB", con)
}

.getQueryDef <- getterConstructor('query_def', 'query', WHERE='query_id')
#' @rdname QueryDef-methods
#' @aliases getQueryDef,blastReportFb-method
setMethod("getQueryDef", "blastReportDB", function (x, id) .getQueryDef(x, id))

.getQueryLen <- getterConstructor('query_len', 'query', WHERE='query_id', as='integer')
#' @rdname QueryLen-methods
#' @aliases getQueryLen,blastReportDB-method
setMethod("getQueryLen", "blastReportDB", function (x, id) .getQueryLen(x, id))

.getHitID <- getterConstructor('hit_id', 'hit', WHERE='query_id',as='integer')
#' @rdname HitID-methods
#' @aliases getHitID,blastReportDB-method
setMethod("getHitID", "blastReportDB", function (x, id)  .getHitID(x, id))

.getHitNum <- getterConstructor('hit_num', 'hit', WHERE='query_id',as='integer')
#' @rdname HitNum-methods
#' @aliases getHitNum,blastReportDB-method
setMethod("getHitNum", "blastReportDB", function (x, id) .getHitNum(x, id))

.getHitLen <- getterConstructor('length', 'hit', WHERE='query_id',as='integer')
#' @rdname HitLen-methods
#' @aliases getHitLen,blastReportDB-method
setMethod("getHitLen", "blastReportDB", function (x, id) .getHitLen(x, id))

.getAccession <- getterConstructor('accession', 'hit', WHERE='query_id')
#' @rdname Accession-methods
#' @aliases getAccession,blastReportDB-method
setMethod("getAccession", "blastReportDB", function (x, id) .getAccession(x, id))

.getGeneID <- getterConstructor('gene_id', 'hit', WHERE='query_id',as='integer')
#' @rdname GeneID-methods
#' @aliases getGeneID,blastReportDB-method
setMethod("getGeneID", "blastReportDB", function (x, id) .getGeneID(x, id))

.getHitDef <- getterConstructor('definition', 'hit', WHERE='query_id')
#' @rdname HitDef-methods
#' @aliases getHitDef,blastReportDB-method
setMethod("getHitDef", "blastReportDB", function (x, id) .getHitDef(x, id))

.getHspHitID <- getterConstructor('hit_id', 'hsp', WHERE='query_id', as='integer')
.getMaxHspHitID <- getterConstructor('hit_id', 'hsp', WHERE='query_id',
                                      FUN='MAX',VAL='bit_score',as='integer')
#' @rdname HspHitID-methods
#' @aliases getHspHitID,blastReportDB-method
setMethod("getHspHitID", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxHspHitID(x,id)
  } else {
    .getHspHitID(x, id)
  }
})

.getHspID <- getterConstructor('hsp_id', 'hsp', WHERE='query_id', as='integer')
.getMaxHspID <- getterConstructor('hsp_id', 'hsp', WHERE='query_id',
                                      FUN='MAX',VAL='bit_score',as='integer')
#' @rdname HspID-methods
#' @aliases getHspID,blastReportDB-method
setMethod("getHspID", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxHspID(x,id)
  } else {
    .getHspID(x, id)
  }
})

.getHspNum <- getterConstructor('hsp_num', 'hsp', WHERE='query_id', as='integer')
.getMaxHspNum <- getterConstructor('hsp_num', 'hsp', WHERE='query_id',
                                      FUN='MAX',VAL='bit_score',as='integer')
#' @usage getHspNum(x, id)
#' @rdname HspNum-methods
#' @aliases getHspNum,blastReportDB-method
#' @docType methods
setMethod("getHspNum", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxHspNum(x,id)
  } else {
    .getHspNum(x, id)
  }
})

.getBitscore <- getterConstructor('bit_score', 'hsp', WHERE='query_id', as='numeric')
#' @rdname Bitscore-methods
#' @aliases getBitscore,blastReportDB-method
setMethod("getBitscore", "blastReportDB", function (x, id, max = FALSE, sum=FALSE) {
  if (max) {
    .getMaxBitscore(x,id)
  } else if (sum) {
    .getTotalBitscore(x,id)
  } else {
    .getBitscore(x,id)
  }
})
.getMaxBitscore <- getterConstructor('MAX(bit_score)','hsp',WHERE='query_id', as='numeric')
#' @rdname Bitscore-methods
#' @aliases getMaxBitscore,blastReportDB-method
setMethod("getMaxBitscore", "blastReportDB", function (x, id){
  .getMaxBitscore(x, id)
})
.getTotalBitscore <- getterConstructor('SUM(bit_score)','hsp',WHERE='query_id', as='numeric')
#' @rdname Bitscore-methods
#' @aliases getTotalBitscore,blastReportDB-method
setMethod("getTotalBitscore", "blastReportDB", function (x, id) {
  .getTotalBitscore(x, id)
})

.getScore <- getterConstructor('score', 'hsp', WHERE='query_id', as='integer')
.getMaxScore <- getterConstructor('MAX(score)', 'hsp', WHERE='query_id', as='integer')
#' @rdname Score-methods
#' @aliases getScore,blastReportDB-method
setMethod("getScore", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxScore(x,id)
  } else {
    .getScore(x, id)
  }
})

.getEvalue <- getterConstructor('evalue', 'hsp', WHERE='query_id', as='numeric')
.getMinEvalue <- getterConstructor('MIN(evalue)', 'hsp', WHERE='query_id', as='numeric')
#' @rdname Evalue-methods
#' @aliases getEvalue,blastReportDB-method
setMethod("getEvalue", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .getMinEvalue(x,id)
  } else {
    .getEvalue(x, id)
  }
})

.getQueryFrom <- getterConstructor('query_from', 'hsp', WHERE='query_id', as='integer')
.getMaxQueryFrom <- getterConstructor('query_from', 'hsp', WHERE='query_id',
                                   FUN='MAX',VAL='bit_score',as='integer')
#' @rdname QueryFrom-methods
#' @aliases getQueryFrom,blastReportDB-method
setMethod("getQueryFrom", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxQueryFrom(x,id)
  } else {
    .getQueryFrom(x, id)
  }
})

.getQueryTo <- getterConstructor('query_to', 'hsp', WHERE='query_id', as='integer')
.getMaxQueryTo <- getterConstructor('query_to', 'hsp', WHERE='query_id',
                                      FUN='MAX',VAL='bit_score',as='integer')
#' @rdname QueryTo-methods
#' @aliases getQueryTo,blastReportDB-method
setMethod("getQueryTo", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .getMaxQueryTo(x,id)
  } else {
    .getQueryTo(x, id)
  }
})

#' @rdname QueryRange-methods
#' @aliases getQueryRange,blastReportDB-method
setMethod("getQueryRange", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .range(x,id,'query',max=TRUE)
  } else {
    .range(x,id,'query',max=FALSE)
  }
})

.getHitFrom <- getterConstructor('hit_from', 'hsp', WHERE='query_id', as='integer')
.getMaxHitFrom <- getterConstructor('hit_from', 'hsp', WHERE='query_id',
                                    FUN='MAX',VAL='bit_score',as='integer')
#' @rdname HitFrom-methods
#' @aliases getHitFrom,blastReportDB-method
setMethod("getHitFrom", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .getMaxHitFrom(x,id)
  } else {
    .getHitFrom(x, id)
  }
})

.getHitTo <- getterConstructor('hit_to', 'hsp', WHERE='query_id', as='integer')
.getMaxHitTo <- getterConstructor('hit_to', 'hsp', WHERE='query_id',
                                    FUN='MAX',VAL='bit_score',as='integer')
#' @rdname HitTo-methods
#' @aliases getHitTo,blastReportDB-method
setMethod("getHitTo", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .getMaxHitTo(x,id)
  } else {
    .getHitTo(x, id)
  }
})

#' @rdname HitRange-methods
#' @aliases getHitRange,blastReportDB-method
setMethod("getHitRange", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .range(x,id,'hit',max=TRUE)
  } else {
    .range(x,id,'hit',max=FALSE)
  }
})

.getQueryFrame <- getterConstructor('query_frame', 'hsp', WHERE='query_id', as='integer')
.getMaxQueryFrame <- getterConstructor('query_frame','hsp',WHERE='query_id',
                                     FUN='MAX',VAL='bit_score', as='integer')
#' @rdname QueryFrame-methods
#' @aliases getQueryFrame,blastReportDB-method
setMethod("getQueryFrame", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxQueryFrame(x,id)
  } else {
    .getQueryFrame(x, id)
  }
})

.getHitFrame <- getterConstructor('hit_frame', 'hsp', WHERE='query_id', as='integer')
.getMaxHitFrame <- getterConstructor('hit_frame','hsp',WHERE='query_id',
                                     FUN='MAX',VAL='bit_score', as='integer')
#' @rdname HitFrame-methods
#' @aliases getHitFrame,blastReportDB-method
setMethod("getHitFrame", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
      .getMaxHitFrame(x,id)
    } else {
      .getHitFrame(x, id)
    }
})

.getIdentity <- getterConstructor('identity', 'hsp', WHERE='query_id', as='integer')
.getMaxIdentity <- getterConstructor('identity','hsp',WHERE='query_id',
                                             FUN='MAX',VAL='bit_score', as='integer')
#' @rdname Identity-methods
#' @aliases getIdentity,blastReportDB-method
setMethod("getIdentity", "blastReportDB", function (x, id, max= FALSE) {
  if (max) {
    .getMaxIdentity(x,id)
  } else {
    .getIdentity(x, id)
  }
})

.getPositive <- getterConstructor('positive', 'hsp', WHERE='query_id', as='integer')
.getMaxPositive <- getterConstructor('positive', 'hsp', WHERE='query_id',
                                     FUN='MAX', VAL='bit_score', as='integer')
#' @rdname Positive-methods
#' @aliases getPositive,blastReportDB-method
setMethod("getPositive", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    unlist( .getMaxPositive(x, id) )
  } else {
    .getPositive(x, id)
  }
})

.getGaps <- getterConstructor('gaps', 'hsp', WHERE='query_id', as='integer')
.getMaxGaps <- getterConstructor('gaps','hsp',WHERE='query_id',
                                 FUN='MAX',VAL='bit_score',as='integer')
#' @rdname Gaps-methods
#' @aliases getGaps,blastReportDB-method
setMethod("getGaps", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxGaps(x, id)
  } else {
    .getGaps(x,id)
  }
})

.getAlignLen <- getterConstructor('align_len', 'hsp', WHERE='query_id', as='integer')
.getMaxAlignLen <- getterConstructor('align_len','hsp',WHERE='query_id',
                                 FUN='MAX',VAL='bit_score',as='integer')
#' @rdname AlignLen-methods
#' @aliases getAlignLen,blastReportDB-method
setMethod("getAlignLen", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
      .getMaxAlignLen(x,id)
    } else {
      .getAlignLen(x, id)
      }
  })

.getQuerySeq <- getterConstructor('qseq', 'hsp', WHERE='query_id')
.getMaxQuerySeq <- getterConstructor('qseq','hsp',WHERE='query_id',
                                 FUN='MAX',VAL='bit_score',as='character')
#' @rdname QuerySeq-methods
#' @aliases getQuerySeq,blastReportDB-method
setMethod("getQuerySeq", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
      .getMaxQuerySeq(x,id)
    } else {
      .getQuerySeq(x, id)
      }
  })

.getHitSeq <- getterConstructor('hseq', 'hsp', WHERE='query_id')
.getMaxHitSeq <- getterConstructor('hseq','hsp',WHERE='query_id',
                                     FUN='MAX',VAL='bit_score',as='character')
#' @rdname HitSeq-methods
#' @aliases getHitSeq,blastReportDB-method
setMethod("getHitSeq", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxHitSeq(x,id)
  } else {
    .getHitSeq(x, id)
  }
})

.getMatch <-getterConstructor('midline', 'hsp', WHERE='query_id')
.getMaxMatch <- getterConstructor('midline','hsp',WHERE='query_id',
                                   FUN='MAX',VAL='bit_score',as='character')
#' @rdname Match-methods
#' @aliases getMatch,blastReportDB-method
setMethod("getMatch", "blastReportDB", function (x, id,max=FALSE) {
  if (max) {
    .getMaxMatch(x,id)
  } else {
    .getMatch(x, id)
  }
})

.getPercIdentity <- getterConstructor(SELECT='CAST(identity AS FLOAT)/CAST(align_len AS FLOAT)',
                                      FROM='(SELECT identity,align_len FROM hsp ',WHERE='query_id ',
                                      as="numeric")
.getMaxPercIdentity <- getterConstructor(SELECT='MAX(CAST(identity AS FLOAT)/CAST(align_len AS FLOAT))',
                                      FROM='(SELECT identity,align_len FROM hsp ',WHERE='query_id ',
                                      as="numeric")
#' @rdname PercIdentity-methods
#' @aliases getPercIdentity,blastReportDB-method
setMethod("getPercIdentity", "blastReportDB", function (x, id, max=FALSE) {
  if (max) {
    .getMaxPercIdentity(x,paste(id,')'))
  } else {
    .getPercIdentity(x,paste(id,')'))
  }
})

#' @rdname PercIdentity-methods
#' @aliases getMaxPercIdentity,blastReportDB-method
setMethod("getMaxPercIdentity", "blastReportDB", function (x, id) {
  .getMaxPercIdentity(x,paste(id,')'))
})

.range <- function(x,id,type, width = FALSE, max=FALSE) {
   pos <- getterFromToRange(x,id,type,max)
   colnames(pos) <- c('frame','from','to')
   start <- ifelse(pos$frame >= 0L, pos$from, pos$to)
   end <- ifelse(pos$frame >= 0L, pos$to, pos$from)
   r <- IRanges(start, end)
   if (width) width(reduce(r)) else r
}

#' @rdname QueryCoverage-methods
#' @aliases getQueryCoverage,blastReportDB-method
setMethod("getQueryCoverage", "blastReportDB", function (x, id) {
  sum(.range(x,id,type='query', width=TRUE))/unlist(getQueryLen(x,id))
})

#' @rdname HitCoverage-methods
#' @aliases getHitCoverage,blastReportDB-method
setMethod("getHitCoverage", "blastReportDB", function (x, id) {
  sum(.range(x,id,type='hit', width=TRUE))/unlist(getQueryLen(x,id))
})

#' @aliases show,blastReportDB-method
#' @rdname show-methods
setMethod('show', 'blastReportDB',
          function (object) {
            n <- db_count(object, "query")
            showme <- sprintf('%s object with %s query rows',
                              sQuote(class(object)), n)
            cat(showme, sep="\n")
          })