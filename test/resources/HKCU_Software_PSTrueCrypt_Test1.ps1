Import-Module .\RegistryModule

New-SubKey "00000001" 'MarcsTaxDocs'    'D:\Google Drive\1pw'                           'Y' 'TrueCrypt' -Timestamp
New-SubKey "00000002" 'BobsTaxDocs'     'C:\Users\Bob\Documents\BobsContainer'          'T' 'TrueCrypt'
New-SubKey "00000003" 'AlicesTaxDocs'   'C:\Users\Alice\Documents\AlicesContainer'      'V' 'VeraCrypt' -Timestamp
New-SubKey "00000004" 'Krytos'          'D:\Google Drive\krytos.tc'                     'K' 'TrueCrypt'