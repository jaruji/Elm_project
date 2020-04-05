module TimeFormat exposing (..)
import Time exposing(Month, toDay, toMonth, toYear)

formatTime: Time.Posix -> String
formatTime time =
    String.fromInt(Time.toDay Time.utc time)
    ++ helper (Time.toDay Time.utc time)
    ++ " of "
    ++ monthToString (Time.toMonth Time.utc time)
    ++ " "
    ++ String.fromInt (Time.toYear Time.utc time)
    ++ ", "
    ++ String.fromInt (Time.toHour Time.utc time)
    ++ ":"
    ++ minuteToString (Time.toMinute Time.utc time)

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
            "Jan"
        Time.Feb ->
            "Feb"
        Time.Mar ->
            "Mar"
        Time.Apr ->
            "Apr"
        Time.May ->
            "May"
        Time.Jun ->
            "Jun"
        Time.Jul ->
            "Jul"
        Time.Aug ->
            "Aug"
        Time.Sep ->
            "Sep"
        Time.Oct ->
            "Oct"
        Time.Nov ->
            "Nov"
        Time.Dec ->
            "Dec"

