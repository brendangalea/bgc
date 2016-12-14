#include <stdlib.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct _Node {
    struct _Node *parent;
    struct _Node *left_child;
    struct _Node *right_sibling;
    struct _Node *leftmost_sibling;
    int type;
} Node;

Node* makeNullNode() {
    Node *node = (Node *) malloc(sizeof(Node));
    node->parent = NULL;
    node->left_child = NULL;
    node->right_sibling = NULL;
    node->leftmost_sibling = node;
    node->type = 0;
    return node;
}

int numSiblings(Node *node) {
    Node *sibs = node->leftmost_sibling;
    int count = 0;
    while (sibs != NULL) {
        count++;
        sibs = sibs->right_sibling;
    }
    return count;
}

/*
 * Add list of right nodes to left lists family
 */
void makeSiblings(Node *left, Node *right) {
    while (left->right_sibling != NULL) {
        left = left->right_sibling;
    }
    Node *rightsibs = right->leftmost_sibling;
    left->right_sibling = rightsibs;
    while (rightsibs != NULL) {
        rightsibs->parent = left->parent;
        rightsibs->leftmost_sibling = left->leftmost_sibling;
        rightsibs = rightsibs->right_sibling;
    }
}

/*
 * Add list of children to parent Node
 */
void adoptChildren(Node *parent, Node *children) {
    if (parent->left_child != NULL) {
        makeSiblings(parent->left_child, children);
    } else {
        Node *ysibs = children->leftmost_sibling;
        parent->left_child = ysibs;
        while (ysibs != NULL) {
            ysibs->parent = parent;
            ysibs = ysibs->right_sibling;
        }
    }
}



int main() {
    return 0;
}
