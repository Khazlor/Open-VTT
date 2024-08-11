#import pdfminer
from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextContainer, LTRect, LTLine, LTCurve
#from pdfminer.pdfparser import PDFParser
#from pdfminer.pdfdocument import PDFDocument
#from pdfminer.pdftypes import resolve1, PDFObjRef
#from pdfminer.psparser import PSLiteral, PSKeyword
#from pdfminer.utils import decode_text

from pypdf import PdfReader
from pypdf.constants import AnnotationDictionaryAttributes

from pprint import pprint

import os


print("enter pdf path")
#text = "S.pdf"
text = input("")

# ================================ labels and polygons ================================

output = "[Vector2(800, 1000), Color(1, 1, 1, 1), ["

current_y = 0

for page_layout in extract_pages(text):
    #print(page_layout)
    current_y += page_layout.height
    for element in page_layout:
        #print(element)
        if isinstance(element, LTTextContainer):
            #label
            #print("text: ", element.get_text())

            #pprint(vars(element))

            #font = ""
            #fsize = 0

            for text_line in element:
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
            #label
            #print("text: ", element.get_text())

            #pprint(vars(element))

            #font = ""
            #fsize = 0

            #for text_line in element:
                #for character in text_line:
                #    font = character.fontname
                #    fsize = character.fontsize
                #    print(fsize)
                #    break
            posx = element.x0
            posy = element.y0 + element.height
            points = ""
            for point in element.pts:
                points += str(point[0] - posx) + ", " + str(posy - point[1]) + ", " 
            BGcolor = [1,1,1,0]
            if element.fill:
                BGcolor = element.non_stroking_color + [1]
            Lcolor = [0,0,0,1]
            if element.stroke:
                Lcolor = element.stroking_color + [1]
            
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



reader = PdfReader(text)
fields = []
current_y = 0
for page in reader.pages:
    for annot in page.annotations:
        annot = annot.get_object()
        if annot[AnnotationDictionaryAttributes.Subtype] == "/Widget":
            fields.append(annot)
            rect = annot["/Rect"]
            pos = str(rect[1]) + ", " + str(rect[0] + current_y)
            size = str(rect[3] - rect[1]) + ", " + str(rect[2] - rect[0])
            #print(annot)
            if "/T" in annot.keys():
                output += (
                    '{\n'+
                    '"BGcolor": Color(1, 1, 1, 0),\n'+
                    '"attr": "' + str(annot["/T"]) + '",\n'+
                    '"fcolor": Color(0, 0, 0, 1),\n'+
                    '"fsize": -1,\n'+
                    '"lcolor": Color(0, 0, 0, 1),\n'+
                    '"left_margin": 5,\n'+
                    '"pos": Vector2(' + pos + '),\n'+
                    '"size": Vector2(' + size + '),\n'+
                    '"type": "input",\n'+
                    '"width": 1\n'+
                    '}, ')
    current_y += page["/CropBox"][2]

#print(output)


if not os.path.exists("output"):
    os.makedirs("output")
f = open("output/output.char_sheet", "w")
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
