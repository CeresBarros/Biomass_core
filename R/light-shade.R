#' Calculate site shade
#'
#' @param time TODO: description neeede
#' @param cohortData TODO: description neeede
#' @param speciesEcoregion TODO: description neeede
#' @param minRelativeB TODO: description neeede
#'
#' @return TODO: description neeede
#'
#' @export
#' @importFrom data.table data.table set setkey
#'
calcSiteShade <- function(time, cohortData, speciesEcoregion, minRelativeB) {
  # the siteshade was calculated based on the code:
  # https://github.com/LANDIS-II-Foundation/Extensions-Succession/blob/master/biomass-succession/trunk/src/PlugIn.cs
  if (nrow(cohortData[age > 5,]) > 0) {
    bAMterm1 <- cohortData[age > 5, ':='(prevMortality = sum(mortality, na.rm = TRUE),
                                         sumB = sum(B, na.rm = TRUE)),
                           by = .(pixelGroup, ecoregionGroup)]
    bAMterm1[is.na(sumB), sumB := 0]
    bAMterm1[is.na(prevMortality), prevMortality := 0]
    bAMterm1 <- unique(bAMterm1, by = c("pixelGroup", "ecoregionGroup"))
    #set(cohortData, NULL, "prevMortality", NULL)
  } else {
    bAMterm1 <- unique(cohortData, by = c("pixelGroup", "ecoregionGroup"))[
      , .(pixelGroup, ecoregionGroup)][
        , ':='(prevMortality = 0, sumB = 0)]
  }
  #bAM <- data.table(speciesEcoregion)[year <= time(sim) & (year > (time(sim)-P(sim)$successionTimestep))]
  bAM <- speciesEcoregionLatestYear(speciesEcoregion, time)
  bAM <- na.omit(bAM) # remove ecoregion-species groups with no maxB or maxANPP
  bAM <- bAM[, .(maxMaxB = max(maxB, na.rm = TRUE)), by = ecoregionGroup]
  setkey(bAM, ecoregionGroup)
  setkey(bAMterm1, ecoregionGroup)
  bAMterm1 <- bAM[bAMterm1, nomatch = 0]
  bAMterm1[, sumB := pmin((maxMaxB - prevMortality), sumB)]
  bAMterm1[, bAM := sumB/maxMaxB]
  minRelativeB <- data.table(minRelativeB)
  setkey(minRelativeB, ecoregionGroup)
  bAMterm1 <- minRelativeB[bAMterm1, nomatch = 0]
  bAMterm1$bAM <- round(bAMterm1$bAM, 3)

  # This is faster than using cut
  bAMterm1[, siteShade := which(bAM < unique(c(0, X1, X2, X3, X4, X5, 1.1)))[1]-2,
           by = pixelGroup]
  # b[, siteShade := as.integer(cut(bAM, sort(unique(c(0, X1, X2, X3, X4, X5, 1))),
  #                            labels = FALSE, right = FALSE, include.lowest = TRUE) - 1),
  #           by = pixelGroup]
  # if (!all.equal(b$siteShade, bAMterm1$siteShade))
  #   stop("aaaaa")
  bAMterm1 <- bAMterm1[, .(pixelGroup, siteShade)]
  return(bAMterm1)
}
