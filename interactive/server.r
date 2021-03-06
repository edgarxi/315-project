# team members: edgar xi [esx], eric wang [ewang1], taylor vigliot [tvigliot], jai ghose (jghose)
# url: https://edgar-eric-taylor-315.shinyapps.io/interactive/
library(shiny)
library(ggplot2)
# library(RCurl)
# library(dplyr)
# library(magrittr)
library(plotly)
library(ggmap)
library(plyr)
# library(radarchart)

function(input, output) {
    df = read.csv("undergrad.csv")
    df$adm_rate = as.numeric(as.character(df$adm_rate))
    df$STEM <- df$eng_deg + df$engtech_deg + df$math_deg + df$sci_deg
    df$repay_rate <- as.numeric(as.character(df$repay_rate))
    df$default_rate <- as.numeric(as.character(df$default_rate))
    # print(df$population)

    filtered_scatter = reactive({
      scatter = subset(df, adm_rate >= input$adm_rate[1] & adm_rate <= input$adm_rate[2])
        #df %>% filter(., adm_rate <= input$acc_adjust)
      return (scatter)
      })

    filtered_scatter_2 = reactive({
      scatter = subset(df, adm_rate >= input$adm_rate_2[1] & adm_rate <= input$adm_rate_2[2])
        #df %>% filter(., adm_rate <= input$acc_adjust)
      return (scatter)
      })
    # filtered_colleges = reactive({
    #     colleges = subset(df, college == input$e1)
    # })


    school_type = reactive({
    if (input$school_type == 'All') { #Filter based on selected school type (All, Public, Private, Non-Profit)
      (df_sub = df)
    } else if (input$school_type == 'Public') {
      # print(df$school_type)
      (df_sub = subset(df, school_type == 'Public'))
    } else if (input$school_type == 'Private Non-Profit') {
      (df_sub = df %>%  filter(., school_type == 'PrivateNonProfit'))
    } else {
      (df_sub = df %>%  filter(., school_type == 'PrivateForProfit'))
    }
    # filter by acceptance rate as well
    df_sub_acc <- subset(df_sub, adm_rate >= input$adm_rate2[1] & adm_rate <= input$adm_rate2[2] )

    #filter by population too
    # df_sub_acc_pop <- subset(df_sub_acc, population >= input$population[1] & population <= input$population[2])
    return (df_sub_acc)
    })

    output$earnings_plot <- renderPlotly({
      # p2 <- ggplot(filtered_scatter(),
      #             aes(x = avg_cost , y =md_earnings_10 ,text = college, color = school_type) )+
      #             geom_point(cex = 0.8) +
      #             labs(
      #                 x= "average yearly cost",
      #                 y = "median earnings 10 years after graduation",
      #                 color = "School Type",
      #                 title = "10 year earnings vs college cost, filtered by college selectivity")
      #             # theme(axis.text.y = element_text(angle = 90, hjust = 1))
      # ggplotly(p2, width = 600, height = 400)
      x <- list(
          title = "average yearly cost"
      )
      y <- list(
          title = "median earnings"
      )
      filtered_scatter() %>% plot_ly(x = ~avg_cost, y = ~md_earnings_10, color = ~school_type) %>%
      add_markers(
          text = ~paste(college, "\npopulation: ",population, "\n acceptance rate: ", adm_rate)
          , hoverinfo = "text") %>%
          layout(xaxis = x, yaxis = y, title = "10 year earnings vs college cost, filtered by college sensitivity")
    })
    #
    # output$earnings_by_school <- renderPlot({
    #   ggplot(school_type(), aes(x = md_earnings_10)) + geom_density() +
    #   labs(x = "Median earnings 10 years after graduation", y= "Density", title = "Median postgraduate earnings filtered by type of school (profit, nonprofit, not-for-profit")
    #   })

    #TODO: handle missing data
    # TODO: avoid rerendering ggmap layer every time call to reactive is made
    output$plot2 <- renderPlotly({

        g <- list(
            scope = 'usa',
            projection = list(type = 'albers usa'),
            showland = TRUE,
            landcolor = toRGB("gray95"),
            subunitcolor = toRGB("gray85"),
            countrycolor = toRGB("gray85"),
            countrywidth = 0.5,
            subunitwidth = 0.5
        )
        # map_base <- get_map(location='united states', zoom=4, maptype = "terrain",
        #      source='google',color='color')
        # plot_2 <- ggmap(map_base)
        # geom_point(aes(x = long, y = lat, size = population, color = adm_rate), data = school_type())
        # # scale_color_distiller(palette = "RdPu")
        # ggplotly(plot_2)
        plot_geo(school_type(), lat = ~lat, lon = ~long, text = ~college,
        size = ~population, mode = "markers", color = ~adm_rate, colors = c("red", "green"))%>%
        add_markers(
            text = ~paste(college, "\npopulation: ",population, "\n acceptance rate: ", adm_rate)
            , hoverinfo = "text") %>%
        layout(geo =g, title = "Colleges in the United States")

    })

    df$school_type <- factor(df$school_type)
    df$school_type <- fct_recode(df$school_type, Public = "1", PrivateNonProfit = "2", PrivateForProfit = "3")

    output$eric_plot1 <- renderPlotly({
        x <- list(
            title = "median earnings 10 years after graduation"
        )
        df %>% plot_ly(x = ~md_earnings_10, frame = ~school_type, type = "histogram") %>%
        layout(xaxis = x, title = "Median Earnings by school type") %>%
        animation_opts(1000, transition = .5,easing = 'elastic', redraw = TRUE) %>%
        animation_slider(currentvalue = list(prefix = "TYPE: ", font = list(color = "green")))
          #
          # p3 <- ggplot(df, aes(x = avg_fam_inc, fill = school_type)) +
          #   geom_histogram(binwidth = 10000) + facet_grid(~factor(school_type)) +
          #   labs(title = "Average Family Income by School Type",x = "Average Family Income",
          #     y = "Number of Schools", fill = "School Type") +
          #     theme(axis.text.y = element_text(angle = 90, hjust = 1))
          # ggplotly(p3)
      })

    output$eric_plot2 <- renderPlotly({

        x <- list(
            title = "average family income"
        )
        y <- list(
            title = "median postgraduate earnings"
        )
        df %>% plot_ly(x = ~avg_fam_inc, y = ~md_earnings_10, color = ~school_type) %>%
        add_markers(
            text = ~paste(college, "\npopulation: ",population, "\n acceptance rate: ", adm_rate)
            , hoverinfo = "text") %>%
            layout(xaxis = x, yaxis = y, title = "Postgraduate Earnings vs Average Family Income")
      # p4 <- ggplot(df, aes(x = avg_fam_inc, y = md_earnings_10, text = college, color = school_type)) +
      #   geom_point(cex = 0.75) +
      #   labs(title = "Earnings vs. Average Family Income",
      #     x = "\nAverage Family Income",
      #     y = "Earnings",
      #     color = "School Type")
      #   # theme(axis.text.y = element_text(angle = 90, hjust = 1))
      # ggplotly(p4)
      })

    output$jai_plot1 <- renderPlotly({

        x <- list(
            title= "percent of students recieving pell grants"
        )

        y <- list(
            title = "average debt repayment rate"
        )

        df %>% plot_ly ( x = ~pct_pell, y = ~repay_rate, color = ~school_type, hoverinfo = "text") %>%
        add_markers(
            text = ~paste(college, "\npopulation: ",population, "\n acceptance rate: ", adm_rate,
            "\n percent receiving pell grants: ", pct_pell)
            , hoverinfo = "text") %>%
            layout(xaxis = x, yaxis = y, title = "debt repayment rate vs pell grant recieving rate")


      #   p5 <- ggplot(df, aes(x = pct_pell, y = repay_rate, text = college, color = school_type)) +
      #   geom_point(cex =0.75) +
      #   labs(
      #       title = "debt repayment rate vs pell grant recieving rate",
      #       x = "percent of students recieving pell grants",
      #       y = "average debt repayment rate",
      #       color = "School Type") +
      #   theme(axis.text.y = element_text(angle = 90, hjust = 1))
      # # p5 <- ggplot(undergrad, aes(x = md_earnings_10, col = school_type)) + geom_density()
      # ggplotly(p5)
      })

    output$jai_plot2 <- renderPlotly({
        # x <- list(
        #     title = "Median Debt (USD)"
        # )
        #  y <- list(
        #      title = "Density"
        #  )
        #  df %>% plot_ly ( x = ~md_debt, color = ~school_type, hoverinfo = "text", type = "density") %>%
        #  add_markers(
        #      text = ~paste(college, "\npopulation: ",population, "\n acceptance rate: ", adm_rate)
        #      , hoverinfo = "text") %>%
        #      layout(xaxis = x, yaxis = y, title = "debt repayment rate vs pell gratn recieving rate")

      p6 <- ggplot(df, aes(x = md_debt, color = school_type)) +
        geom_density() +
        labs(x="Median Debt (USD)", y="Density",
             color="School Type", title="Median Student Debt Distributions by School Type") +
             theme(axis.text.y = element_text(angle = 90))
      ggplotly(p6, width = 700, height = 400)
      })

    output$plot_7 <- renderPlotly({

      p7 <- ggplot(filtered_scatter_2(), aes(x = default_rate, col = school_type), alpha = 0.3) + geom_density() +
        labs (x = "default rate", y = "density", title = "default rates as a function of selectivity")
      ggplotly(p7, width = 700, height =400)
      })

    output$plot_8 <- renderPlotly({
      p8 <- ggplot(df, aes(x = adm_rate, y = avg_cost)) +
        stat_density_2d(aes(fill = ..level..), geom = "polygon", alpha = 0.3) +
        geom_point(aes(text = college, col = school_type)) +
        labs(title = "Admissions Rate vs Average Cost", x = "Admission Rate", y = "Average Cost", color = "school type") +
        theme(axis.text.y = element_text(angle = 90, hjust = 1)) +
        guides(fill = F)

      ggplotly(p8, width = 700, height = 400)

      })

  }
