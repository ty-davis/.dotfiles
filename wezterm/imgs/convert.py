from PIL import Image
import sys

def main(argv):
    in_name = argv[1] if len(argv) > 1 else 'img_in.jpg'
    out_name = argv[2] if len(argv) > 2 else 'img_out.jpg'

    img = Image.open(in_name)
    img.save(out_name)


if __name__ == '__main__':
    main(sys.argv)
