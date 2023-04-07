*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Email.Exchange
Library           RPA.Archive
Library           RPA.RobotLogListener
Library           RPA.Assistant

*** Variables ***

${GLOBAL_RETRY_AMOUNT}    	 10x
${GLOBAL_RETRY_INTERVAL}     3s

${RoboStartURL}            https://robotsparebinindustries.com/#/robot-order
${locator_cookies_ok}      //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
${locator_input_head}      //*[@id="head"]
${locator_input_body}      body
${locator_input_legs}      css:[placeholder|='Enter the part number for the legs']
${locator_input_adr}       //*[@id="address"]
${locator_button_preview}    //*[@id="preview"]
${locator_img_preview}    //*[@id="robot-preview-image"]
${locator_button_order}    //*[@id="order"]
${locator_button_nextorder}    //*[@id="order-another"]
${locator_div_receipt}    //*[@id="receipt"]
${locator_div_image}    //*[@id="robot-preview-image"]
${OrderFilesURL}           https://robotsparebinindustries.com/orders.csv
@{Orders} 
${DOWNLOAD_PATH}           ${OUTPUT DIR}${/}downloads${/}orders.csv    
${RECIEPTS_PATH}           ${OUTPUT DIR}${/}reciepts${/}   
${pdf}
${receipt_table}              
*** Keywords ***

User Input Task
    [Documentation]
    ...    Using user input
    ...    https://robotsparebinindustries.com/#/robot-order
    #Clear Dialog
    Add Heading    Input from User
    Add Text Input     text_input    Please enter URL
    Add submit buttons    buttons=Submit,Cancel    default=Submit
    ${result}=    Run dialog

    ${url}=    Set Variable    ${result}[text_input]
    Log To Console    ${url}
    Open the robot order Website    ${url}    
Open the robot order Website
    [Arguments]    ${myURL}
    # Open Available Browser        ${RoboStartURL}
    Open Available Browser        ${myURL}
   
Get Orders
    Download        ${OrderFilesURL}     overwrite=${True}    target_file=${DOWNLOAD_PATH} 
    ${tmp}=    Read table from CSV     ${DOWNLOAD_PATH} 
    Return From Keyword     ${tmp}

Log Orders 
    [Arguments]    @{myOrders} 
    FOR    ${Order}    IN    @{myOrders}
        Log    ${Order}
    END        

Close the annoying modal
       Wait Until Keyword Succeeds    
        ...    ${GLOBAL_RETRY_AMOUNT}    
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click Button When Visible     ${locator_cookies_ok}

Fill the Forms
    [Arguments]    @{myOrders}
    FOR    ${Order}    IN    @{myOrders}
        Run Keyword And Continue On Failure    Fill the Form    ${Order}
    END

Fill the Form 
    [Arguments]    ${Order}
        Select From List By Value   ${locator_input_head}    ${Order}[Head]
        Select Radio Button    ${locator_input_body}    ${Order}[Body]
        Input Text    ${locator_input_legs}    ${Order}[Legs]
        Input Text    ${locator_input_adr}    ${Order}[Address]
        Click Button    ${locator_button_preview}
        Wait Until Keyword Succeeds    
        ...    ${GLOBAL_RETRY_AMOUNT}    
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click Button    ${locator_button_order}
        Capture Element Screenshot    ${locator_img_preview}    ${OUTPUTDIR}${/}id_image_id-1.png
        ${pdf}=     Store the receipt as a PDF file    ${Order}[Order number]
        Add Img 2 receipt    
        ...    ${pdf}    
        ...    ${OUTPUTDIR}${/}id_image_id-1.png
        Log    ${pdf}
        Wait Until Keyword Succeeds    
        ...    ${GLOBAL_RETRY_AMOUNT}    
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click Element If Visible    ${locator_button_nextorder}
        Close the annoying modal

Store the receipt as a PDF file
    [Arguments]    ${Order}
    ${myPath}    set Variable    ${RECIEPTS_PATH}${Order}.pdf
    ${receipt_table}=     Get Element Attribute    ${locator_div_receipt}    outerHTML 
    Html To Pdf    ${receipt_table}    ${myPath} 
    RETURN     ${myPath}   

Add Img 2 receipt
    [Arguments]    ${pdfPath}    ${image}
    
    Open Pdf    ${pdfPath}
    Add Watermark Image To Pdf    ${image}  ${pdfPath}
    Close Pdf

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}reciepts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}reciepts
    ...    ${zip_file_name}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Mute Run On Failure       :Fill the Form
    # Open the robot order Website
    User Input Task
    @{Orders}=     Get Orders
    Log Orders       @{Orders}
    Close the annoying modal
    Fill the Forms    @{Orders}
    Create ZIP package from PDF files
  
