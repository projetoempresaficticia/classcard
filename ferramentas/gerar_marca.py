#!/usr/bin/env python3
"""Prepara a marca e o fundo do ClassCard a partir dos originais.

A marca é bicolor (rede branca dentro de um disco azul), por isso vai
como PNG com transparência e não como máscara — um canal só perdia o
branco. Mesmo caso do Subsight, ao contrário do Prepacoin.

Produz:
  web/marca/classcard-512.png      a marca, quadrada, com transparência
  web/marca/fundo-entrada.webp     o fundo, largo
  web/marca/fundo-entrada.jpg      reserva para quem não suporte WebP
  web/marca/fundo-entrada-movel.webp  a faixa central, para telemóvel
  apple-touch-icon.png             180x180 sobre branco (o iOS não
                                   respeita transparência)
  favicon-32.png / favicon.ico
"""

import pathlib
from PIL import Image

RAIZ = pathlib.Path(__file__).resolve().parent.parent
ICONE = pathlib.Path(r"C:/Users/devel/Downloads/ChatGPT Image 4 de set. de 2026, 23_09_04.png")
FUNDO = pathlib.Path(r"C:/Users/devel/Downloads/ChatGPT Image 4 de set. de 2026, 23_11_47.png")


def quadrado(caixa):
    """Alarga a caixa para ficar quadrada. Preenche, nunca estica."""
    x0, y0, x1, y1 = caixa
    lado = max(x1 - x0, y1 - y0)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    meio = lado // 2
    return (cx - meio, cy - meio, cx - meio + lado, cy - meio + lado)


def main():
    for f in (ICONE, FUNDO):
        if not f.is_file():
            raise SystemExit(f'não encontro o original: {f}')

    destino = RAIZ / 'web' / 'marca'
    destino.mkdir(parents=True, exist_ok=True)

    # ── a marca ──────────────────────────────────────────────────────
    im = Image.open(ICONE).convert('RGBA')
    caixa = quadrado(im.getchannel('A').getbbox())
    marca = im.crop(caixa)
    print('marca recortada em', caixa, '->', caixa[2] - caixa[0], 'px de lado')

    def redim(lado):
        return marca.resize((lado, lado), Image.LANCZOS)

    # A marca aparece no cabeçalho a 38px. Guardar 512 eram 227 KB para
    # desenhar 38 — 128px chega para ecrãs de densidade tripla, e sai em
    # WebP com PNG de reserva.
    for lado, nome in ((128, 'classcard-marca'),):
        m = redim(lado)
        alvo = destino / f'{nome}.webp'
        m.save(alvo, 'WEBP', quality=92, method=6)
        print(f'escrito web/marca/{nome}.webp  {alvo.stat().st_size/1024:.0f} KB')
        reserva = destino / f'{nome}.png'
        m.save(reserva, optimize=True)
        print(f'escrito web/marca/{nome}.png   {reserva.stat().st_size/1024:.0f} KB')

    # a de 512 fica para partilha e para quem precise de a ampliar
    redim(512).save(destino / 'classcard-512.png', optimize=True)
    print('escrito web/marca/classcard-512.png')

    # O iOS não respeita transparência no ícone do ecrã inicial: o que
    # fosse transparente saía preto. Compõe-se sobre branco.
    base = Image.new('RGBA', (180, 180), (255, 255, 255, 255))
    base.alpha_composite(redim(180))
    base.convert('RGB').save(RAIZ / 'apple-touch-icon.png', optimize=True)
    print('escrito apple-touch-icon.png')

    redim(32).save(RAIZ / 'favicon-32.png', optimize=True)
    redim(256).save(RAIZ / 'favicon.ico',
                    sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
    print('escritos favicon-32.png e favicon.ico')

    # ── o fundo ──────────────────────────────────────────────────────
    fundo = Image.open(FUNDO).convert('RGB')
    print('fundo original', fundo.size, f'{FUNDO.stat().st_size/1024:.0f} KB')

    largo = destino / 'fundo-entrada.webp'
    fundo.save(largo, 'WEBP', quality=86, method=6)
    print(f'escrito web/marca/fundo-entrada.webp  {largo.stat().st_size/1024:.0f} KB')

    reserva = destino / 'fundo-entrada.jpg'
    fundo.save(reserva, 'JPEG', quality=84, optimize=True, progressive=True)
    print(f'escrito web/marca/fundo-entrada.jpg   {reserva.stat().st_size/1024:.0f} KB')

    # telemóvel: só a faixa central, que é a zona limpa onde o cartão
    # assenta. As decorações das pontas não caberiam de qualquer forma.
    w, h = fundo.size
    largura = int(h * 0.62)
    x0 = (w - largura) // 2
    estreito = fundo.crop((x0, 0, x0 + largura, h))
    estreito = estreito.resize((720, int(720 * h / largura)), Image.LANCZOS)
    movel = destino / 'fundo-entrada-movel.webp'
    estreito.save(movel, 'WEBP', quality=84, method=6)
    print(f'escrito web/marca/fundo-entrada-movel.webp {estreito.size} '
          f'{movel.stat().st_size/1024:.0f} KB')


if __name__ == '__main__':
    main()
