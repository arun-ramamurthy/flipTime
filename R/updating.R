#' @title{TimeUnitsToSeconds}
#' @description Converts a number of minutes, hours, days, weeks or months to seconds.
#' @param x The period expressed in \code{units} units.
#' @param units The time unit, which can be seconds, minutes, days, weeks or months.
#' @importFrom lubridate %m+%
#' @export
TimeUnitsToSeconds <- function(x, units = "seconds") {

    unit.list <- c("seconds", "minutes", "hours", "days", "weeks", "months")
    if (!(units %in% unit.list)) {
        stop("Unrecognized units.")
    }

    if (units == "months")
    {
        today <- Sys.Date()
        future <- today %m+% months(x)
        return((future - today) * 3600 * 24)
    }

    secs <- c(1, 60, 3600, 3600 * 24, 3600 * 24 * 7)
    return(x * secs[match(units, unit.list)])
}

#' @title{UpdateEvery}
#' @description Sets a period of time, after which an R object is woken and updated.
#' @param x The period expressed in \code{units} units.
#' @param units The time unit, which can be seconds, minutes, days, weeks or months.
#' @details If \code{units} = "months" then \code{x} must be an integer. The update time
#' will roll back to the last day of the previous month if no such day exists \code{x} months
#' forward from today.
#' @examples
#' UpdateEvery(5, "days")
#' UpdateEvery(1, "months")
#' @export
UpdateEvery <- function(x, units = "seconds") {

    seconds <- TimeUnitsToSeconds(x, units)
    message.string <- paste0("R output expires in ", seconds, " seconds with wakeup")
    message(message.string)
}


#' @title{UpdateAt}
#' @description Sets date and time after which an R object is woken and updated, then a frequency for periodic updates.
#' @param x Character vector to be parsed into a date and time.
#' @param us.format Whether to use the US convention for dates.
#' @param time.zone An optional time zone, or else default of 'UTC' applies.
#' See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones for a list of time zones.
#' @param units The time unit for regular updates, which can be seconds, minutes, days, weeks or months.
#' @param frequency The period of regular updates, expressed in \code{units} units.
#' @details If \code{units} = "months" then \code{frequency} must be an integer. The update time
#' will roll back to the last day of the previous month if no such day exists after stepping
#' forwards a multiple of \code{frequency} months.
#' @examples
#' UpdateAt("31-1-2017 10:00:00", time.zone = "Australia/Sydney", units = "months", frequency = 1)
#' UpdateAt("05-15-2017 18:00:00", us.format = TRUE, time.zone = "America/New_York",
#' units = "days", frequency = 3)
#' @importFrom lubridate %m+%
#' @export
UpdateAt <- function(x, us.format = FALSE, time.zone = "UTC", units = "days", frequency = 1) {

    first.update <- ParseDateTime(x, us.format = us.format, time.zone = time.zone)
    now <- Sys.time()
    attr(now, "tzone") <- time.zone

    if (now < first.update)
    {
        secs.to.first <- round(difftime(first.update, now, units = "secs"))
        message("R output expires in ", secs.to.first, " seconds with wakeup")
        return()
    }

    # first.update is in the past
    secs.since.first <- as.numeric(round(difftime(now, first.update, units = "secs")))
    if (units != "months")
    {
        secs.frequency <- round(TimeUnitsToSeconds(frequency, units))
        secs.to.next <- secs.frequency - (secs.since.first %% secs.frequency)
        message("R output expires in ", secs.to.next, " seconds with wakeup")
        return()
    }

    next.update <- first.update
    step <- 0
    while (next.update < now)
    {
        step <- step + frequency
        next.update <- first.update %m+% months(step)
    }
    secs.to.next <- round(difftime(next.update, now, units = "secs"))
    message("R output expires in ", secs.to.next, " seconds with wakeup")
}