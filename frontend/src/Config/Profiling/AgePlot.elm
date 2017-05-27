module Config.Attribution.AgePlot exposing (profilingPlot)

{-| Similar to Config.Attribution.Plots
-}

import Html exposing (text, div)
import Html.Attributes exposing (class)
import Plot exposing (group, viewBarsCustom, defaultBarsPlotCustomizations, BarGroup, MaxBarWidth(Percentage), Bars, normalAxis)
import Svg.Attributes exposing (fill)
import Dict exposing (Dict)
import PlotSlideShow exposing (Plot)
import Regex exposing (Regex, regex)
import Data.Profiling.Prediction exposing (..)


profilingPlot : Dict String (Plot AgePrediction msg)
profilingPlot =
    let
        data =
            [ { label = "age"
              , title = "age distribution"
              , render = plotAges
              , description = div [ class "text-left box" ] [ text "Probability for age" ]
              }
            ]
    in
        List.map (\datum -> ( datum.label, PlotSlideShow.plot datum )) data
            |> Dict.fromList


customizations : Plot.PlotCustomizations msg
customizations =
    { defaultBarsPlotCustomizations | margin = { top = 20, right = 40, bottom = 40, left = 50 } }


groups : (data -> List BarGroup) -> Bars data msg
groups toGroups =
    let
        pinkFill =
            "rgba(253, 185, 231, 0.5)"

        blueFill =
            "#e4eeff"
    in
        { axis = normalAxis
        , toGroups = toGroups
        , styles = [ [ fill pinkFill ], [ fill blueFill ] ]
        , maxWidth = Percentage 75
        }


plotAges : Prediction -> Html.Html msg
plotAges { age } =
    let
        data =
            [ ( "18 to 24", [ age.range18_24 ] )
            , ( "25 to 34", [ age.range25_34 ] )
            , ( "35 to 49", [ age.range35_49 ] )
            , ( "50 to 64", [ age.range50_64 ] )
            , ( "more than 64", [ age.range65_xx ] )
            ]
    in
        viewBarsCustom customizations (groups (List.map (\( label, value ) -> group label value))) data
