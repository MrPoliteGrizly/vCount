from update.forms import *
from django.shortcuts import render, redirect
from django.http import HttpResponse
from vCountDjGui.auxilary import isLoggedIn, closeSession, getPageDictionary, getLanguageByRequest, getErrorList, getPageString
import os
from vCountDjGui.auxilary import rootDir 
from django.views.decorators.csrf import csrf_protect
from update.forms import UpdateForm
import re

update_finished_flag=os.path.join(rootDir(), 'vCount/update/', "updatefinished.flag")

@csrf_protect
def index(request):
    if not isLoggedIn(request):
        return redirect('/login/')
    
    dictum = getPageDictionary(request, 'updateForm')
    lang = getLanguageByRequest(request)
    
    if request.method == 'POST':
        
        if request.FILES and request.FILES.get('filename'):
            request.POST['filename'] = request.FILES['filename']
            
            expr = re.compile(r'^\w+\.tar.gz.c$')
            if bool(expr.match(request.FILES['filename'].name)):
                handle_uploaded_file(request.FILES['filename'])
                return HttpResponse(dictum['fileLoadMessage'])
            else:
                return HttpResponse(getPageString('updateForm', 'incorrectFileError', lang))
        else:
            return HttpResponse(dictum['chooseFileError'])
        
    else:
        updateform = UpdateForm(lang)
        
    
    return render(request, 'update/update_form.html', {'form' : updateform,'dictum': dictum})

def handle_uploaded_file(f):
    with open(os.path.join(rootDir(), 'vCount/update/', os.path.basename(f.name)), 'wb+') as destination:
        for chunk in f.chunks():
            destination.write(chunk)
    
    os.system(os.path.join(rootDir(), 'vCount/webupdate.sh'))
    
@csrf_protect
def getUpdateStatus(request):
    if os.path.isfile(update_finished_flag):
        dictum = getPageDictionary(request, 'updateForm')
        return HttpResponse(dictum['updateFinished'])
    else:
        return HttpResponse('False')