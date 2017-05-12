module Config.Attribution.Plots exposing (plots)

{-| Describes how we want to draw our plots (and which ones to draw)

Most of the heavy lifting is actually done by PlotSlideShow, which
will keep track of which plot has focus and how the title and description
are laid out around the plot.
-}

import Html exposing (text)
import Plot exposing (group, viewBarsCustom, defaultBarsPlotCustomizations, BarGroup, MaxBarWidth(Percentage), Bars, normalAxis)
import Svg.Attributes exposing (fill)
import Dict exposing (Dict)
import PlotSlideShow exposing (Plot)
import Regex exposing (Regex, regex)
import Data.Attribution.Statistics exposing (Statistics)


plots : Dict String (Plot Statistics msg)
plots =
    let
        data =
            [ { label = "punctuation"
              , title = "punctuation per character"
              , render = plotPunctuation
              , description = text "The usage of punctuation is indicative of the author based on ... "
              }
            , { label = "line endings"
              , title = "line endings per character"
              , render = plotLineEndings
              , description = text "The usage of line endings is indicative of the author based on ... "
              }
            , { label = "anagram SIM"
              , title = "anagram similarity"
              , render = plotNgramsSim
              , description = text "anagram similarity measures ... "
              }
            , { label = "anagram SPI"
              , title = "anagram SPI"
              , render = plotNgramsSpi
              , description = text "anagram spi measures ... "
              }
            , { label = "similarities"
              , title = "similarities"
              , render = plotSimilarities
              , description = text "similarities about punctuation, line_endings, line_length, letter_case, and text_block"
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


{-| Construct a plot for punctuation

This module uses the excellent elm-plot package http://package.elm-lang.org/packages/terezka/elm-plot/latest

First we must turn the two punctuation dictionaries into something that elm-plot understands.
This is what construct does. Construct also scales the values, so all bar size's are withing one order of magnitude of one another.

List.map2 "zips together" two lists, for example

    List.map2 (+) [ 1,2 ] [ 13, 14 ] == [11, 16 ]

Finally, uncurry

    uncurry : (a -> b -> c) -> ((a, b) -> c)
    uncurry f (x, y) = f x y

    (uncurry (++)) ("foo", "bar") == "foobar"

allows us to use a normal function that takes two arguments, and apply it to a tuple containing two values.

Plot.viewBars takes care of all the rest.
-}
plotPunctuation : Statistics -> Html.Html msg
plotPunctuation { known, unknown } =
    let
        construct : ( Char, Float ) -> ( Char, Float ) -> ( String, List Float )
        construct ( label, v1 ) ( _, v2 ) =
            ( String.fromChar label, [ v1 / known.characters, v2 / known.characters ] )
    in
        List.map2 construct (Dict.toList known.punctuation) (Dict.toList unknown.punctuation)
            |> viewBarsCustom customizations (groups (List.map (uncurry group)))


plotLineEndings : Statistics -> Html.Html msg
plotLineEndings { known, unknown } =
    let
        construct ( label, v1 ) ( _, v2 ) =
            ( String.fromChar label, [ v1 / known.lines, v2 / unknown.lines ] )
    in
        List.map2 construct (Dict.toList known.lineEndings) (Dict.toList unknown.lineEndings)
            |> viewBarsCustom customizations (groups (List.map (uncurry group)))


plotAverages : Statistics -> Html.Html msg
plotAverages { known, unknown } =
    let
        data =
            [ ( "sentence length", [ known.sentences / known.lines, unknown.sentences / unknown.lines ] )
            , ( "words per line", [ known.words / known.lines, unknown.words, unknown.lines ] )
              -- , ( "lines per paragraph", [ known.lines / known.blocks, unknown.lines / unknown.blocks ] )
              -- , ( "uppercase per lowercase", [ known.uppers / known.lowers, unknown.uppers / unknown.lowers ] )
            ]
    in
        viewBarsCustom customizations (groups (List.map (\( label, value ) -> group label value))) data


plotNgramsSim : Statistics -> Html.Html msg
plotNgramsSim { ngramsSim } =
    let
        construct ( key, value ) =
            ( toString key, [ value ] )
    in
        ngramsSim
            |> Dict.toList
            |> List.map construct
            |> viewBarsCustom customizations (groups (List.map (uncurry group)))


plotNgramsSpi : Statistics -> Html.Html msg
plotNgramsSpi { ngramsSpi } =
    let
        construct ( key, value ) =
            ( toString key, [ toFloat value ] )
    in
        ngramsSpi
            |> Dict.toList
            |> List.map construct
            |> viewBarsCustom customizations (groups (List.map (uncurry group)))


plotSimilarities : Statistics -> Html.Html msg
plotSimilarities { similarity } =
    let
        rename : String -> String
        rename str =
            str
                |> Regex.replace Regex.All (Regex.regex "_") (\_ -> " ")

        construct ( key, value ) =
            ( rename key, [ value ] )
    in
        similarity
            |> Dict.toList
            |> List.map construct
            |> viewBarsCustom customizations (groups (List.map (uncurry group)))
