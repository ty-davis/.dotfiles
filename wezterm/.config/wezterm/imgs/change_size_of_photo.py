from PIL import Image
import sys

def main(argv):
    fin_name = argv[1] if len(argv) > 1 else 'img_in.png'
    fout_name = argv[2] if len(argv) > 2 else 'img_out.png'
    position = argv[3] if len(argv) > 3 else 'center'
    position = position if position in ['top', 'bottom', 'center', 'left', 'right'] else 'center'
    x_dim = int(argv[4]) if len(argv) > 4 else 1920
    y_dim = int(argv[5]) if len(argv) > 5 else 1080

    img = Image.open(fin_name)
    aspect = img.size[0] / img.size[1]
    print("CURRENT IMAGE ASPECT RATIO:", aspect)

    target_aspect = x_dim / y_dim
    print("TARGET IMAGE ASPECT RATIO:", target_aspect)

    x_proportion = min(target_aspect / aspect, 1)
    y_proportion = min(aspect / target_aspect, 1)

    print("PROPORTIONS:", (x_proportion, y_proportion))

    new_width = int(img.size[0] * x_proportion)
    new_height = int(img.size[1] * y_proportion)

    print("NEW DIMENSIONS BEFORE RESIZE:", (new_width, new_height))


    left = 0
    top = 0

    x_diff = img.size[0] - new_width
    y_diff = img.size[1] - new_height

    if position == 'center':
        left = int(x_diff / 2)
        top = int(y_diff / 2)
    elif position == 'bottom':
        top = y_diff
    elif position == 'right':
        left = x_diff

    crop = (left, top, left + new_width, top + new_height)


    img_cropped = img.crop(crop)
    img_cropped = img_cropped.resize((x_dim, y_dim))
    img_cropped.save(fout_name)


if __name__ == "__main__":
    main(sys.argv)
