module TimeFormat exposing (..)
import TimeZone
import Time exposing(Month, toDay, toMonth, toYear)

formatTime: Time.Posix -> String
formatTime time =
    let
        zone = TimeZone.europe__bratislava ()
    in
    formatDate time
    ++ ", "
    ++ String.fromInt (Time.toHour zone time)
    ++ ":"
    ++ minuteToString (Time.toMinute zone time)

formatDate: Time.Posix -> String
formatDate time =
    let
        zone = TimeZone.europe__bratislava ()
    in
    monthToString (Time.toMonth zone time)
    ++ " "
    ++ String.fromInt(Time.toDay zone time)
    ++ " "
    ++ String.fromInt (Time.toYear zone time)

getMonth: Time.Posix -> String
getMonth time =
    let
        zone = TimeZone.europe__bratislava ()
    in
        monthToString (Time.toMonth zone time)

minuteToString: Int -> String
minuteToString min =
    if min < 10 then
        ("0" ++ String.fromInt min)
    else
        String.fromInt min

helper: Int -> String
helper day =
    case day of
        1 ->
            "st"
        2 ->
            "nd"
        3 ->
            "rd"
        _ ->
            "th"

monthToString: Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "January"
        Time.Feb ->
            "February"
        Time.Mar ->
            "March"
        Time.Apr ->
            "April"
        Time.May ->
            "May"
        Time.Jun ->
            "June"
        Time.Jul ->
            "July"
        Time.Aug ->
            "August"
        Time.Sep ->
            "September"
        Time.Oct ->
            "October"
        Time.Nov ->
            "November"
        Time.Dec ->
            "December"

