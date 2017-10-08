# -*- mode: python -*-

block_cipher = None


a = Analysis(['sigthief.py'],
             pathex=['C:\\Users\\Sec504\\Desktop\\meta_twin\\src\\SigThief-master'],
             binaries=[],
             datas=[],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='sigthief',
          debug=False,
          strip=False,
          upx=True,
          runtime_tmpdir=None,
          console=True )
