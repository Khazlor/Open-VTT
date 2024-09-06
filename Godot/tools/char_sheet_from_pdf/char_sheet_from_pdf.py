#import pdfminer
import sys
from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextContainer, LTRect, LTLine, LTCurve
#from pdfminer.pdfparser import PDFParser
#from pdfminer.pdfdocument import PDFDocument
#from pdfminer.pdftypes import resolve1, PDFObjRef
#from pdfminer.psparser import PSLiteral, PSKeyword
#from pdfminer.utils import decode_text

from pypdf import PdfReader
from pypdf import PdfWriter
from pypdf.constants import AnnotationDictionaryAttributes

from pprint import pprint

import os


if not len(sys.argv) > 1:
    print("error - no file entered")
    exit()
name_of_file = sys.argv[1]
output_name = name_of_file.split('.')[0]

if len(sys.argv) > 2:
    page_rotate_array = sys.argv[2].split(",")
    output_pdf = PdfWriter()
    reader = PdfReader(name_of_file)
    counter = 0
    for page in reader.pages:
        if page_rotate_array[counter] != 0:
            output_pdf.add_page(page.rotate(int(page_rotate_array[counter]) * 90))
        counter += 1
    output_pdf.write("temp_rotated.pdf")
    name_of_file = "temp_rotated.pdf"


# ================================ labels and polygons ================================

output = "[Vector2(800, 1000), Color(1, 1, 1, 1), ["

current_y = 0

for page_layout in extract_pages(name_of_file):
    current_y += page_layout.height
    for element in page_layout:
        if isinstance(element, LTTextContainer):
            #label
            for text_line in element:
                if not hasattr(text_line, 'x0'):
                    continue
                #for character in text_line:
                #    font = character.fontname
                #    fsize = character.fontsize
                #    print(fsize)
                #    break
                output += (
                '{\n'+
                '"BGcolor": Color(1, 1, 1, 0),\n'+
                '"fcolor": Color(0, 0, 0, 1),\n'+
                '"fsize": -1,\n'+
                '"halign": 0,\n'+
                '"lcolor": Color(0, 0, 0, 1),\n'+
                '"pos": Vector2(' + str(round(text_line.x0)) + ', ' + str(round(current_y - text_line.y0 - text_line.height)) + '),\n'+
                '"size": Vector2(' + str(round(text_line.width)) + ', ' + str(round(text_line.height)) + '),\n'+
                '"text": "' + text_line.get_text()[:-1] + '",\n'+
                '"type": "label",\n'+
                '"valign": 0,\n'+
                '"width": 0\n'+
                '}, ')

        if isinstance(element, LTRect) or isinstance(element, LTCurve) or isinstance(element, LTLine):
            #Lines and shapes
            posx = element.x0
            posy = element.y0 + element.height
            points = ""
            for point in element.pts:
                points += str(point[0] - posx) + ", " + str(posy - point[1]) + ", " 
            BGcolor = [1,1,1,0]
            if element.fill:
                BGcolor = list(element.non_stroking_color) + [1]
            Lcolor = [0,0,0,1]
            if element.stroke:
                Lcolor = list(element.stroking_color) + [1]
            
            output += (
            '{\n'+
            '"BGcolor": Color(' + str(BGcolor)[1:-1] + '),\n'+
            '"lcolor": Color(' + str(Lcolor)[1:-1] + '),\n'+
            '"points": PackedVector2Array(' + points[:-2] + '),\n'+
            '"pos": Vector2(' + str(round(posx)) + ', ' + str(round(current_y - element.y0 - element.height)) + '),\n'+
            '"size": Vector2(' + str(round(element.width)) + ', ' + str(round(element.height)) + '),\n'+
            '"type": "polygon",\n'+
            '"width": ' + str(element.linewidth) + '\n'+
            '}, ')

            

#print(output)


# ====================================== forms ======================================



reader = PdfReader(name_of_file)
current_y = 0
for page in reader.pages:
    page_rotation = page["/Rotate"] #WARNING annotation /Rect is not rotated - needs to be rotated manually
    if page_rotation == 0 or page_rotation == 180:
        current_y += page["/CropBox"][3]
    if page_rotation == 90 or page_rotation == 270:
        current_y += page["/CropBox"][2]
    pos = ""
    size = ""
    margin = 0
    for annot in page.annotations:
        annot = annot.get_object()
        if annot[AnnotationDictionaryAttributes.Subtype] == "/Widget":
            #print(annot)
            if "/T" in annot.keys():
                rect = annot["/Rect"]
                if page_rotation == 0:
                    pos = str(rect[0]) + ", " + str(current_y - rect[3])
                    size = str(rect[2] - rect[0]) + ", " + str(rect[3] - rect[1])
                    margin = 5
                    if rect[2] - rect[0]: #if size.x < 30 - no margin
                        margin = -1
                if page_rotation == 90:
                    pos = str(rect[1]) + ", " + str(current_y - (page["/CropBox"][2] - rect[0]))
                    size = str(rect[3] - rect[1]) + ", " + str(rect[2] - rect[0])
                    margin = 5
                    if rect[1] - rect[3]: #if size.x < 30 - no margin
                        margin = -1
                if page_rotation == 180:
                    pos = str(page["/CropBox"][2] - rect[2]) + ", " + str(current_y - (page["/CropBox"][3] - rect[1]))
                    size = str(rect[2] - rect[0]) + ", " + str(rect[3] - rect[1])
                    margin = 5
                    if rect[0] - rect[2]: #if size.x < 30 - no margin
                        margin = -1
                if page_rotation == 270:
                    pos = str(page["/CropBox"][3] - rect[3]) + ", " + str(current_y - rect[2])
                    size = str(rect[3] - rect[1]) + ", " + str(rect[2] - rect[0])
                    margin = 5
                    if rect[3] - rect[1]: #if size.x < 30 - no margin
                        margin = -1
                fsize = -1
                if not "/Ff" in annot:
                    print("no form flags ", str(annot["/T"]), " - treating as singleline")
                elif annot["/Ff"] & 4096: #multiline
                    print("multiline ", str(annot["/T"]))
                    fsize = 10
                print(rect, size)
                output += (
                    '{\n'+
                    '"BGcolor": Color(1, 1, 1, 0),\n'+
                    '"attr": "' + str(annot["/T"]) + '",\n'+
                    '"fcolor": Color(0, 0, 0, 1),\n'+
                    '"fsize": ' + str(fsize) + ',\n'+
                    '"lcolor": Color(0, 0, 0, 1),\n'+
                    '"left_margin": ' + str(margin) + ',\n'+
                    '"pos": Vector2(' + pos + '),\n'+
                    '"size": Vector2(' + size + '),\n'+
                    '"type": "input",\n'+
                    '"width": 1\n'+
                    '}, ')

#print(output)

if not os.path.exists(output_name):
    os.makedirs(output_name)
f = open(output_name + "/" + output_name + ".char_sheet", "w")
f.write(output[:-2] + "]]")
f.close()

print("Done")


'''
with open(text, 'rb') as fp:
    parser = PDFParser(fp)

    doc = PDFDocument(parser)
    res = resolve1(doc.catalog)

    if 'AcroForm' not in res:
        raise ValueError("No AcroForm Found")

    fields = resolve1(doc.catalog['AcroForm'])['Fields']  # may need further resolving

    for f in fields:
        field = resolve1(f)
        name= field.get('T')
        name = decode_text(name)
        

        pprint(name)
        page = field.get('P')
        pos = ""
        size = ""


        pprint(field.get('Rect'))

        output += (
                '{\n'+
                '"BGcolor": Color(1, 1, 1, 0),\n'+
                '"attr": "' + name + '",\n'+
                '"fcolor": Color(0, 0, 0, 1),\n'+
                '"fsize": -1,\n'+
                '"lcolor": Color(0, 0, 0, 1),\n'+
                '"pos": Vector2(' + pos + '),\n'+
                '"size": Vector2(' + size + '),\n'+
                '"type": "input",\n'+
                '"width": 1\n'+
                '}, ')
                '''
