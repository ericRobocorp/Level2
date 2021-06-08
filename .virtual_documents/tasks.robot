*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library     RPA.Browser.Selenium
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.FileSystem
Library     RPA.Dialogs
Library     RPA.Robocloud.Secrets


*** Keywords ***
Open the robot order website
    Open Available Browser       https://robotsparebinindustries.com/#/robot-order
    Click Button    OK


*** Keywords ***
Get Orders
    Download    https://robotsparebinindustries.com/orders.csv  target_file=${CURDIR}${/}output${/}orders.csv  overwrite=true
    ${orders}=    Read Table From Csv   ${CURDIR}${/}output${/}orders.csv   header=true
    [Return]    ${orders}


*** Keywords ***
Fill the form
    [Arguments]     ${row}
    Select From List By Value   head    ${row}[Head]  #1-6
    Select Radio Button    body    ${row}[Body]
    Input Text   xpath: /html/body/div/div/div[1]/div/div[1]/form/div[3]/input   ${row}[Legs]
    Input Text   address    ${row}[Address]


*** keywords***
Preview the robot
    Click Button    Preview


*** Keywords ***
Submit the order
    Click Button    order
    Page Should Contain Button     order-another


*** Keywords ***
Create order PDF
    [Arguments]     ${orderNum}
    Wait Until Element Is Visible    id:order-completion
    ${order_results_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_results_html}    ${CURDIR}${/}output${/}order${/}${orderNum}.pdf


*** Keywords ***
Take screenshot
    [Arguments]     ${orderNum}
    Wait Until Element Is Visible    robot-preview
    Capture Element Screenshot    robot-preview    ${CURDIR}${/}output${/}images${/}${orderNum}.png


*** Keywords ***
Combine PDF
    [Arguments]     ${orderNum}
    #Open Pdf    ${CURDIR}${/}output${/}images${/}${orderNum}.png
    ${files}=    Create List
    ...    ${CURDIR}${/}output${/}images${/}${orderNum}.png 
    ...    ${CURDIR}${/}output${/}order${/}${orderNum}.pdf
    Add Files To Pdf    ${files}   ${CURDIR}${/}output${/}${orderNum}_FinalOrder.pdf


*** Keywords ***
Order another robot
    Click Button    order-another
    Click Button    OK


*** keywords ***
Create a ZIP file of the receipts
    Archive folder with zip     ${CURDIR}${/}output${/}   ${CURDIR}${/}allOrders.zip   include=*_FinalOrder.pdf


*** Keywords ***
Some user input
    ${secret}=  Get Secret  myURL
    Add icon    Success
    Add heading   Would you like to go to ${secret}[theURL]
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF   $result.submit == "Yes"
        #Delete working folder
        Add icon    Warning
        Add Heading   Too bad, that's for another lesson. Have a great day!
        Add submit buttons    buttons=OK
        Run Dialog
    END


*** Keywords ***
Delete working folder
    #Remove Directory    ${CURDIR}${/}output     recursive=true
    ${files}=   List Files In Directory    ${CURDIR}${/}output${/}images
    FOR    ${file}  IN  @{FILES}
        Run Keyword If File Exists   "\*.png"    Remove file    ${file}
    END


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
    #     Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    5x    .5s    Submit the order
        Create order PDF    ${order}[Order number]
        Take screenshot     ${order}[Order number]
        Combine PDF     ${order}[Order number]
        Order another robot
    END
    Create a ZIP file of the receipts
    Some user input
    #Delete working folder
    [Teardown]  Close Browser
