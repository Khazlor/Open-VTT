# PDF to Character Sheet Converter

to run this tool you will need:

### Python enviroment
- python3.8 or newer

### Python PDF libraries:
- pdfminer.six
- pypdf

You can install these using pip:
- pip install pdfminer.six
- pip install pypdf

## Usage
1. copy your pdf to this folder
2. use following command to run the tool:
- python char_sheet_from_pdf.py <your_pdf_file.pdf> [comma separated list of page rotations]

exaple:
- python char_sheet_from_pdf.py char_sheet.pdf 1,2,-1,0

        will convert char_sheet.pdf with:
            first page rotated 90° clockwise,
            second page rotated 180° clockwise,
            third page rotated 90° counter-clockwise,
            fourth page not rotated

3. wait for conversion to complete
4. IMPORTANT - open and resave created .char_sheet file to in any text editor (notepad, kate, etc.) - otherwise fails to parse in Godot - probably CRLF related problem
5. copy created folder to saves/character_sheets
6. open character sheet in character sheet editor to calculate Label font sizes and make any final adjustments
7. save character sheet - ready for use
    