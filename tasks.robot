*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           Collections
#Library          MyLibrary
#Resource         keywords.robot
#Variables        MyVariables.py
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    close the browser

*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    OrderingWebsite
    Log    ${url}
    Open Available Browser    ${url}[orderlink]
    #https://robotsparebinindustries.com/#/robot-order

Get orders
    ${csv}=    Collect CSV File From User
    Download    ${csv}    overwrite=True
    #https://robotsparebinindustries.com/orders.csv
    ${key_orders}    Read table from CSV    orders.csv
    [Return]    ${key_orders}

Collect CSV File From User
    Add heading    Orders CSV file
    Add text input    URL    label=Orders CSV file link
    ${response}=    Run dialog
    [Return]    ${response}[URL]

Close the annoying modal
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    FOR    ${i}    IN RANGE    9999999
        Click Button    Order
        ${isvisible}=    Is Element Visible    id:receipt
        Exit For Loop If    ${isvisible}==True
    END
    Log    Exited the loop.

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Keyword Succeeds    3x    1s    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Keyword Succeeds    3x    1s    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    css:#robot-preview-image    ${OUTPUT_DIR}${/}receipts${/}robot_${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}receipts${/}robot_${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True

Go to order another robot
    Wait Until Element Is Visible    id:receipt
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    receipts.zip

close the browser
    Close Browser
