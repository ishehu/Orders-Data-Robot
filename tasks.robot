*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Assistant dialog
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${row}    IN    @{orders}
        Close annoying modal
        Fill the form for one order    ${row}
        Preview the robot
        Submit the order
        Store order receipt as a PDF file    ${row}
        Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${row}
        Go to order another robot
    END
    Create ZIP file of the PDF receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    robotsparebin
    Open Available Browser    ${secret}[website]

Close annoying modal
    Click Button    OK

Fill the form for one order
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Click Element    id-body-${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Wait Until Page Contains Element    id:order
    Wait Until Element Is Visible    id:robot-preview-image
    TRY
        Wait Until Keyword Succeeds    2 min    0.5 sec    Click Element When Visible    id:order
    FINALLY
        Wait Until Keyword Succeeds    2 min    200ms    Click Element If Visible    id:order
    END
    TRY
        Wait Until Keyword Succeeds    5x    5 sec    Click Element If Visible    id:order
    EXCEPT
        Log    Catches any error
    FINALLY
        Wait Until Keyword Succeeds    3x    strict:200ms    Click Element If Visible    id:order
    END
    Wait Until Keyword Succeeds    3x    0.5 sec    Click Element If Visible    id:order

Store order receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts/${row}[Order number].pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}receipts/${row}[Order number].png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${pdf}=    Open Pdf    ${OUTPUT_DIR}${/}receipts/${row}[Order number].pdf
    ${screenshot}=    Create list
    ...    ${OUTPUT_DIR}${/}receipts/${row}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}receipts/${row}[Order number].png:align=center,orientation=P
    Add Files To Pdf    ${screenshot}    ${OUTPUT_DIR}${/}receipts/${row}[Order number].pdf
    Close Pdf    ${pdf}

Go to order another robot
    Click Element When Visible    id:order-another

Create ZIP file of the PDF receipts
    ${embeded_pdf_receipt}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${embeded_pdf_receipt}
    Empty Directory    ${OUTPUT_DIR}${/}receipts

Assistant dialog
    Add heading    Please enter orders url address link
    Add text input    link    label=Orders URL Address
    ${result}=    Run dialog
    Download    ${result.link}    overwrite=True
