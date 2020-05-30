module Pages.Profile.History exposing (..)
import LineChart
import LineChart.Colors as Colors
import LineChart.Junk as Junk
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Title as Title
import LineChart.Axis.Range as Range
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Values as Values
import LineChart.Junk as Junk
import LineChart.Dots as Dots
import LineChart.Grid as Grid
import LineChart.Dots as Dots
import LineChart.Line as Line
import LineChart.Colors as Colors
import LineChart.Events as Events
import LineChart.Legends as Legends
import LineChart.Container as Container
import LineChart.Interpolation as Interpolation
import LineChart.Axis.Intersection as Intersection
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import User
import Server
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)
import Time
import TimeFormat

{--
    Tab of profile that shows up only if the user is logged in and is viewing his own profile.
    Displays user upload activity by using a line chart.
--}

type alias Model =
  {
    user: User.Model
    , status: Status
  }

type alias Point =
  { 
    x : Float
    , y : Float 
  }

type alias Activity =
    {
        day: Int
        , count: Int
    }

type Status
  = Loading
  | Failure
  | Success (List Activity)

type Msg
  = Empty
  | Response (Result Http.Error(List Activity))

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
    model

init: User.Model -> (Model, Cmd Msg)
init user =
    (Model user Loading, Cmd.none)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)
        Response response ->
            case response of
                Ok act ->
                    ({ model | status = Success act }, Cmd.none)
                Err _ ->
                    ({ model | status = Failure }, Cmd.none)

view: Model -> Html Msg
view model =
    div[ class "container"
    , style "text-align" "center"
    , style "min-height" "500px" ][ 
        h3 [] [ text "Activity in the last month" ] 
        , div [ class "help-block" ][
            text "This graph represents your image upload activity in the last month"
        ]
        , case model.status of
            Loading ->
                div[ style "margin-top" "20px" ][
                    Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            Failure ->
                div [ class "alert alert-warning"
                , style "margin" "auto"
                , style "width" "60%" ][
                    text "Failed to load activity data" 
                ]
            Success activity ->
                div [ style "margin-left" "5%"][ 
                    LineChart.viewCustom 
                    { x = xConfig (List.length activity)
                      , y = Axis.default 400 "Uploads" .y
                      , container = Container.responsive "line-chart-1"
                      , interpolation = Interpolation.default
                      , intersection = Intersection.default
                      , legends = Legends.default
                      , events = Events.default
                      , junk = Junk.default
                      , grid = Grid.dots 0.5 Colors.blue
                      , area = Area.default
                      , line = Line.default
                      , dots = Dots.default
                    }
                    [
                        LineChart.line Colors.blue Dots.square "Activity" (List.map toPoint activity)
                    ]
                ]
        , hr [] []
        , h3 [] [ text "My activity" ] 
        , div [ class "help-block" ][
            text "This sections contains logs of your activity" 
        ]
    ]

xConfig: Int -> Axis.Config Point msg
xConfig tickCount =
  Axis.custom
    { title = Title.default "Day"
    , variable = Just << .x
    , pixels = 1000
    , range = Range.default
    , axisLine = AxisLine.rangeFrame Colors.gray
    , ticks = ticksConfig tickCount
    }


ticksConfig: Int -> Ticks.Config msg
ticksConfig ticks =
    Ticks.int ticks

toPoint: Activity -> Point
toPoint act =
    { x = Basics.toFloat act.day, y = Basics.toFloat act.count }

decodeActivity: Decode.Decoder Activity
decodeActivity =
    Decode.succeed Activity
    |> required "day" Decode.int
    |> required "count" Decode.int

get: String -> Int -> Cmd Msg
get username date =
    Http.get{
        url = Server.url ++ "/account/activity" ++ "?username=" ++ username
              ++ "&date=" ++ (String.fromInt date)
        , expect = Http.expectJson Response (Decode.list decodeActivity)
    }